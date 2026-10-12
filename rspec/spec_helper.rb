# RSpec copy of the minitest suite in spec/, kept for a possible future conversion. The minitest suite stays the one
# that CI runs; run this one with `bundle exec rspec` (the .rspec file points it at this directory).
#
# Like the minitest suite it needs a Kestrel 2.4.1 on KJESS_MEMCACHE_PORT (default 33122), and the specs flush every
# queue on that server.
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../spec', __dir__)

require 'thread'
require 'kjess'
require 'utils' # spec/utils.rb: the KJess::Spec helpers (ports, kjess_client, reset_server) shared with the minitest suite

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
end
