# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'visa_net_uy/version'

Gem::Specification.new do |spec|
  spec.name        = 'visa_net_uy'
  spec.version     = VisaNetUy::VERSION
  spec.date        = '2010-04-28'
  spec.summary     = "VisaNet PlugIn for ruby!"
  spec.description = "VisaNet PHP PlugIn port for ruby."
  spec.authors     = ["Andres Pache", "TopTierLabs"]
  spec.email       = 'apache90@gmail.com'
  spec.homepage    = 'http://rubygemspec.org/gems/visa_net_uy'
  spec.license     = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

end
