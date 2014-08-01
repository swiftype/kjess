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

  s.add_development_dependency 'json', '~> 1.7.6'
  s.add_development_dependency 'minitest', '~> 4.5.0'
  s.add_development_dependency 'rake', '~> 10.0.3'
  s.add_development_dependency 'rdoc', '~> 3.12'
  s.add_development_dependency 'zip', '~> 2.0.2'
end
