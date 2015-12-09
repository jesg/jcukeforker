# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jcukeforker/version"

Gem::Specification.new do |s|
  s.name        = "jcukeforker"
  s.version     = JCukeForker::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jason Gowan", "Jari Bakken"]
  s.email       = ["gowanjason@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Library to maintain a forking queue of Cucumber processes, for JRuby}
  s.description = %q{Library to maintain a forking queue of Cucumber processes, with optional VNC displays. Designed for JRuby.}

  s.rubyforge_project = "jcukeforker"

  s.add_dependency "cucumber", ">= 1.1.5", "< 2.0"
  s.add_dependency "vnctools", ">= 0.1.1"
  s.add_dependency "celluloid-io", ">= 0.15.0"
  s.add_dependency "childprocess", ">= 0.5.3"
  s.add_development_dependency "rspec", "2.5"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "rake", "~> 0.9.2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
