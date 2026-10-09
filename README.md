# KJess

* [Homepage](https://github.com/copiousfreetime/kjess/)
* [Github Project](https://github.com/copiousfreetime/kjess)
* email jeremy at copiousfreetime  dot org

## DESCRIPTION

KJess is a pure ruby Kestrel client that supports Kestrel's Memcache style
protocol.

## FEATURES

A pure ruby native client to Kestrel.

## Examples

    client = Kestrel::Client.new( 'k.example.com' )
    client.set( 'my_queue', 'item' )   # put an 'item' on 'my_queue'
    i = client.reserve( 'my_queue' )   # get an item off 'my_queue' with
                                       # Reliable Read

    # do something with the item pulled off the queue

    client.close( 'my_queue' )         # confirm with Kestrel that the item
                                       # retrieved was processed

## Swiftype fork

This repository (`swiftype/kjess`) is Swiftype's fork of [copiousfreetime/kjess](https://github.com/copiousfreetime/kjess).
Upstream has not released since 1.2.0 (2013). Compared with upstream 1.2.0 this fork:

* does not `require 'resolv-replace'` (buggy under multithreaded JRuby) and has a gemspec;
* detects refused connections on MRI 3.x (`KJess::Socket` used to treat a closed port as connected there);
* runs on the Rubies our apps use: **MRI 3.2.8** (website) and **JRuby 9.4.14.0** (crawler);
* has a `Gemfile`, current development dependencies, and an rspec copy of the specs in `rspec/` (the minitest suite in
  `spec/` is the main one);
* is only ever released to our own gem feed (`allowed_push_host` points at the `swiftype-gems` feed on Artifactory,
  never rubygems.org).

It is used by the crawler (JRuby) and the website (MRI).

### Running the specs

The specs talk to a real Kestrel on `localhost:33122` (override with `KJESS_MEMCACHE_PORT`; the text, thrift and admin
ports are `KJESS_TEXT_PORT`, `KJESS_THRIFT_PORT` and `KJESS_ADMIN_PORT`) and assume it reports version 2.4.1
(override with `KJESS_KESTREL_VERSION`). **The specs flush every queue on that server**, so never point them at a Kestrel
that holds real data.

    bundle install
    bundle exec rake test      # the minitest suite
    bundle exec rake rspec     # the rspec copies

Set `COVERAGE=1` to get a SimpleCov report for `rake test`.

### Continuous integration (Buildkite)

* **Pipeline definition:** `.buildkite/pipeline.yml` has one step per runtime (MRI from `.ruby-version`, and JRuby
  9.4.14.0), each running `.buildkite/scripts/run-tests.sh <mri|jruby>` on `docker.elastic.co/swiftype/ci-base-el8`,
  the image the crawler's build uses. It has git, `/opt/rubies/multiruby-mri-3.2.8` and
  `/opt/rubies/multiruby-jruby-9.4.14.0`. The official `jruby` Docker image would not work here: it has no `git`, which
  the Buildkite checkout hook needs.
* **Kestrel:** the image ships a Kestrel jar (`/opt/kestrel/kestrel-2.4.4.jar`; the Swiftype build reports
  `2.4.4-SWIFTYPE10`). The script starts a throw-away instance from it on the spec ports, using a temporary config and
  data directory, and on Java 1.7 because, as the image's own `kestrel-ci` init script notes, Kestrel does not work on
  Java 1.8. It reads the server's version and passes it to the specs as `KJESS_KESTREL_VERSION`, then stops Kestrel when
  the job ends. Each job runs `rake test` and `rake rspec`.
* **Keeping it current:** change the MRI version through `.ruby-version` and the JRuby one through `JRUBY_VERSION` in the
  script and the step label, and keep them in line with the crawler (`.ruby-version`) and the website. Both must exist
  under `/opt/rubies` in the CI image, which is built from the `swiftype-ci-base` repository.
* **Run the same job locally** (this is how it was verified; on Apple Silicon the image needs `--platform linux/amd64`
  and is slow because it is emulated):

      docker run --rm --platform linux/amd64 -v "$PWD":/work -w /work --entrypoint bash \
        docker.elastic.co/swiftype/ci-base-el8 .buildkite/scripts/run-tests.sh mri    # or: jruby

  Run it on a copy of the repository if you do not want the container to write into your checkout.
* **The pipeline itself is not defined in this repository.** Pipelines for `swiftype/*` repositories are registered in
  Elastic's Buildkite separately (for example `swiftype-crawler-build` checks out `swiftype/crawler` using a GitHub token
  from Vault), not through a file in the repo. For this repository a pipeline has to be created that points at
  `swiftype/kjess` with `.buildkite/pipeline.yml` as its pipeline file; until that exists, none of the above runs on pull
  requests.

## ISC LICENSE

<http://opensource.org/licenses/isc-license.txt>

Copyright (c) 2012 Jeremy Hinegardner

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
