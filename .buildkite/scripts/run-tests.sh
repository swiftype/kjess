#!/usr/bin/env bash
#
# Run the kjess specs on one Ruby runtime inside the Swiftype CI image (docker.elastic.co/swiftype/ci-base-el8).
#
#   .buildkite/scripts/run-tests.sh mri      # MRI from .ruby-version (3.2.8)
#   .buildkite/scripts/run-tests.sh jruby    # JRuby 9.4.14.0
#
# The specs need a real Kestrel, so this starts a throw-away one from the image's /opt/kestrel jar on the ports the
# specs use (spec/utils.rb), runs the minitest suite (`rake test`) and the rspec copies (`rake rspec`), and stops Kestrel
# again. The specs flush every queue on that Kestrel, which is fine for a private instance like this one.
#
# Environment (all optional): MRI_VERSION, JRUBY_VERSION, KJESS_MEMCACHE_PORT, KJESS_TEXT_PORT, KJESS_THRIFT_PORT,
# KJESS_ADMIN_PORT.
set -euo pipefail

runtime="${1:-}"
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

MRI_VERSION="${MRI_VERSION:-$(cat .ruby-version)}"
JRUBY_VERSION="${JRUBY_VERSION:-9.4.14.0}"

case "$runtime" in
  mri)   ruby_dir="/opt/rubies/multiruby-mri-${MRI_VERSION}" ;;
  jruby) ruby_dir="/opt/rubies/multiruby-jruby-${JRUBY_VERSION}"; export JAVA_HOME=/usr/lib/jvm/jre-1.8.0 ;;
  *) echo "Usage: $0 mri|jruby" >&2; exit 2 ;;
esac
[[ -d "$ruby_dir" ]] || { echo "Ruby not found in the CI image: $ruby_dir" >&2; exit 1; }
export PATH="${ruby_dir}/bin:${PATH}"

# The CI image ships its own Kestrel build (2.4.4-SWIFTYPE10 at the time of writing). The specs assume 2.4.1 unless told
# otherwise, so the version is read from the running server below.
KESTREL_JAR="${KESTREL_JAR:-/opt/kestrel/kestrel-2.4.4.jar}"

# Same defaults as spec/utils.rb
export KJESS_MEMCACHE_PORT="${KJESS_MEMCACHE_PORT:-33122}"
export KJESS_TEXT_PORT="${KJESS_TEXT_PORT:-9998}"
export KJESS_THRIFT_PORT="${KJESS_THRIFT_PORT:-9992}"
export KJESS_ADMIN_PORT="${KJESS_ADMIN_PORT:-9999}"

work="$(mktemp -d)"
mkdir -p "${work}/data" "${work}/logs"

echo "--- Ruby: $(ruby -v)"

#---------------------------------------------------------------------------------------------------
echo "--- Starting Kestrel from ${KESTREL_JAR} on port ${KJESS_MEMCACHE_PORT}"
cat > "${work}/kjess.scala" <<SCALA
import com.twitter.conversions.storage._
import com.twitter.conversions.time._
import com.twitter.logging.config._
import com.twitter.ostrich.admin.config._
import net.lag.kestrel.config._

new KestrelConfig {
  listenAddress = "0.0.0.0"
  memcacheListenPort = ${KJESS_MEMCACHE_PORT}
  textListenPort = ${KJESS_TEXT_PORT}
  thriftListenPort = ${KJESS_THRIFT_PORT}

  queuePath = "${work}/data"

  clientTimeout = 30.seconds
  expirationTimerFrequency = 1.second
  maxOpenTransactions = 100

  default.defaultJournalSize = 16.megabytes
  default.maxMemorySize = 128.megabytes
  default.maxJournalSize = 1.gigabyte

  admin.httpPort = ${KJESS_ADMIN_PORT}
  admin.statsNodes = new StatsConfig {
    reporters = new TimeSeriesCollectorConfig
  }

  loggers = new LoggerConfig {
    level = Level.INFO
    handlers = new FileHandlerConfig {
      filename = "${work}/logs/kestrel.log"
      roll = Policy.Never
    }
  }
}
SCALA

# The image's own init script (kestrel-ci) runs Kestrel on Java 1.7 because it does not work on 1.8
KESTREL_JAVA="${KESTREL_JAVA:-/usr/lib/jvm/jre-1.7.0/bin/java}"
(cd "$work" && nohup "$KESTREL_JAVA" -server -Xmx512m -Dstage=kjess -jar "$KESTREL_JAR" --no-config-cache \
  -f "${work}/kjess.scala" > "${work}/logs/stdout.log" 2>&1 & echo $! > "${work}/kestrel.pid")

stop_kestrel() {
  kill "$(cat "${work}/kestrel.pid")" 2>/dev/null || true
}
show_kestrel_logs_on_failure() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    echo "^^^ +++ Failed (exit ${status}); Kestrel output:"
    tail -n 30 "${work}/logs/stdout.log" "${work}/logs/kestrel.log" 2>/dev/null || true
  fi
  stop_kestrel
  exit $status
}
trap show_kestrel_logs_on_failure EXIT

for _ in $(seq 1 60); do
  if curl --silent --fail "http://127.0.0.1:${KJESS_ADMIN_PORT}/ping" 2>/dev/null | grep -q pong; then break; fi
  sleep 1
done
curl --silent --fail "http://127.0.0.1:${KJESS_ADMIN_PORT}/ping" | grep -q pong || { echo "Kestrel did not start" >&2; exit 1; }
echo "Kestrel is up"

# Ask the server for its version (memcache `version` command: "VERSION <number>") and tell the specs what to expect
if [[ -z "${KJESS_KESTREL_VERSION:-}" ]]; then
  exec 3<>"/dev/tcp/127.0.0.1/${KJESS_MEMCACHE_PORT}"
  printf 'version\r\n' >&3
  read -r -t 5 version_line <&3 || true
  exec 3>&-
  version_line="${version_line%$'\r'}"
  export KJESS_KESTREL_VERSION="${version_line#VERSION }"
fi
echo "Kestrel version: ${KJESS_KESTREL_VERSION}"

#---------------------------------------------------------------------------------------------------
echo "--- bundle install"
export BUNDLE_PATH="${BUNDLE_PATH:-${work}/bundle}"
bundle install --jobs 4

echo "--- rake test (minitest)"
bundle exec rake test

echo "--- rake rspec (rspec copies)"
bundle exec rake rspec
