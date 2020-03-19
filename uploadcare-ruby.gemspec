
# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uploadcare/ruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'uploadcare-ruby'
  spec.version       = Uploadcare::VERSION
  spec.authors       = ['Stepan Redka']
  spec.email         = ['stepan.redka@railsmuffin.com']

  spec.summary       = 'Ruby wrapper for uploadcare API'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/uploadcare/uploadcare-ruby-next'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/uploadcare/uploadcare-ruby-next'
    spec.metadata['changelog_uri'] = 'https://github.com/uploadcare/uploadcare-ruby-next/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib', 'lib/uploadcare', 'lib/uploadcare/rest']

  spec.add_dependency 'api_struct', '~> 1.0.1'
  spec.add_dependency 'dry-configurable', '~> 0.9.0'
  spec.add_dependency 'parallel'
  spec.add_dependency 'retries'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.55.0'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
end
