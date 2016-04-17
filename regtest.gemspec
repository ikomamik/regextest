# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'regtest/version'

Gem::Specification.new do |spec|
  spec.name          = "regtest"
  spec.version       = Regtest::VERSION
  spec.authors       = ["IKOMA, Mikio"]
  spec.email         = ["mikio.ikoma@gmail.com"]

  spec.summary       = %q{A Ruby library for generating sample data of regular expression}
  spec.description   = %q{This library generates data matched with specified regular expression.}
  spec.homepage      = "https://bitbucket.org/ikomamik/regtest"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
