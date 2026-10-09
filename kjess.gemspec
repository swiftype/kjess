# -*- encoding: utf-8 -*-
$:.push File.join(File.dirname(__FILE__), 'lib')
require "kjess"

Gem::Specification.new do |s|
  s.name        = "kjess"
  s.version     = KJess::VERSION
  s.authors     = ["Jeremy Hinegardner"]
  s.email       = ["jeremy@copiousfreetime.org"]
  s.homepage    = "https://github.com/copiousfreetime/kjess"
  s.summary     = %q{KJess is a pure ruby Kestrel client that supports Kestrel's Memcache style protocol.}
  s.description = %q{KJess is a pure ruby Kestrel client that supports Kestrel's Memcache style protocol.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Never push this fork to rubygems.org (bundler's `rake release` honours this)
  s.metadata['allowed_push_host'] = 'https://artifactory.elastic.dev/artifactory/api/gems/swiftype-gems'

  # minitest 5.x still supports the `describe`/`must_equal` style the specs use (minitest 6 drops global expectations)
  s.add_development_dependency 'minitest', '~> 5.15'
  s.add_development_dependency 'rake', '>= 13'
  s.add_development_dependency 'rubyzip', '>= 2' # only for `rake kestrel:extract`
  s.add_development_dependency 'simplecov'
end
