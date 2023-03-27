# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uploadcare/ruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'uploadcare-ruby'
  spec.version       = Uploadcare::VERSION
  spec.authors       = ['@dmitrijivanchenko (Dmitrij Ivanchenko), @T0mbery (Andrey Aksenov)',
                        'kraft001 (Konstantin Rafalskii)']

  spec.summary       = 'Ruby wrapper for uploadcare API'
  spec.description   = 'Ruby API client that handles uploads and further operations with files ' \
                       'by wrapping Uploadcare Upload and REST APIs.'
  spec.homepage      = 'https://uploadcare.com/'
  spec.license       = 'MIT'
  spec.email         = ['hello@uploadcare.com']

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata = {
      'allowed_push_host' => 'https://rubygems.org',
      'homepage_uri' => spec.homepage,
      'source_code_uri' => 'https://github.com/uploadcare/uploadcare-ruby',
      'changelog_uri' => 'https://github.com/uploadcare/uploadcare-ruby/CHANGELOG.md',
      'bug_tracker_uri' => 'https://github.com/uploadcare/uploadcare-ruby/issues',
      'documentation_uri' => 'https://www.rubydoc.info/gems/uploadcare-ruby/',
      'rubygems_mfa_required' => 'true'
    }
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

  spec.add_dependency 'mimemagic', '~> 0.4'
  spec.add_dependency 'parallel', '~> 1.22'
  spec.add_dependency 'retries', '~> 0.0'
  spec.add_dependency 'uploadcare-api_struct', '>= 1.1', '< 2'

  spec.add_development_dependency 'byebug', '~> 11.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.48'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
