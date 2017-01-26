# -*- encoding: utf-8 -*-
require File.expand_path('../lib/uploadcare/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "uploadcare-ruby"
  gem.authors       = ["@rastyagaev (Vadim Rastyagaev)",
                       "@dimituri (Dimitry Solovyov)",
                       "@romanonthego (Roman Dubinin)"]
  gem.email         = ["hello@uploadcare.com"]
  gem.summary       = "Ruby gem for Uploadcare"
  gem.description   = <<-EOF
                        Ruby wrapper for Uploadcare service API. 
                        Full documentations on api can be found 
                        at https://uploadcare.com/documentation/rest/
                      EOF
  gem.metadata       =  { 
                          "github" => "https://github.com/uploadcare/uploadcare-ruby", 
                          "issue_tracker" => "https://github.com/uploadcare/uploadcare-ruby/issues" 
                        }
  gem.homepage      = "https://uploadcare.com/documentation/libs/"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.version       = Uploadcare::VERSION
  gem.add_runtime_dependency 'faraday', '~> 0.8'
  gem.add_runtime_dependency 'faraday_middleware', '~> 0.9'
  gem.add_runtime_dependency 'multipart-post'
  gem.add_runtime_dependency 'mime-types'

  gem.add_development_dependency 'rspec', "~> 3"
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'pry'
end
