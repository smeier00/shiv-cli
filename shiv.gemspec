# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shiv/version'

Gem::Specification.new do |spec|
  spec.name          = "shiv-cli"
  spec.version       = Shiv::VERSION
  spec.authors       = ["JD Bottorf"]
  spec.email         = ["jd@sdsc.edu"]
  spec.description   = "Shiv command line client interface to internal inventory systems"
  spec.summary       = "Write a gem summary"
  spec.homepage      = "https://shiv.sdsc.edu"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = ["shiv"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "gli"
  spec.add_dependency "highline"
  spec.add_dependency "rest-client"

end
