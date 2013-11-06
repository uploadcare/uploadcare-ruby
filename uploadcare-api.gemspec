# -*- encoding: utf-8 -*-
require File.expand_path('../lib/uploadcare/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "uploadcare-ruby"
  gem.authors       = ["@rastyagaev (Vadim Rastyagaev)",
                       "@dimituri (Dimitry Solovyov)",
                       "@romanonthego (Roman Dubinin)"]
  gem.email         = ["hello@uploadcare.com"]
  gem.description   = "Ruby wrapper for Uploadcare service API."
  gem.summary       = "ruby gem for Uploadcare"
  gem.homepage      = "https://uploadcare.com"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.version       = Uploadcare::VERSION
  gem.add_runtime_dependency 'faraday'
  gem.add_runtime_dependency 'faraday_middleware'
  gem.add_runtime_dependency 'multipart-post'
  gem.add_runtime_dependency 'mime-types'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
end
