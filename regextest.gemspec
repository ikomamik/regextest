# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'regextest/version'

Gem::Specification.new do |spec|
  spec.name          = "regextest"
  spec.version       = Regextest::VERSION
  spec.authors       = ["IKOMA, Mikio"]
  spec.email         = ["mikio.ikoma@gmail.com"]

  spec.summary       = %q{A ruby library for generating sample data of regular expression}
  spec.description   = %q{Regextest generates sample string that matches with regular expression. Unlike similar tools, it recognizes anchors, charactor classes and other advanced notation of ruby regex. Target users are programmers or students for debugging/learning regular expression. You can use [sample application](http://goo.gl/5miiF4) without installation. }
  spec.homepage      = "https://bitbucket.org/ikomamik/regextest"
  spec.license       = "2-clause BSD license (see the file LICENSE.txt)"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "ruby", "~> 1.9.3"
  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "racc", "~> 1.4.12"
  spec.add_development_dependency "yard", "~> 0.9.5"
  spec.add_development_dependency "rspec", "~> 3.5.0"
end
