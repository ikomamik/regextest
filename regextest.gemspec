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
  spec.description   = %q{This library generates data matched with specified regular expression.}
  spec.homepage      = "https://bitbucket.org/ikomamik/regextest"
  spec.license       = "2-clause BSD license (see the file LICENSE.txt)"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "yard", "~> 0.9.5"
  spec.add_development_dependency "rspec"
end
