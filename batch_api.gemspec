# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'batch_api/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'batch_api'
  s.version     = BatchApi::VERSION
  s.authors     = ['Alex Koppel']
  s.email       = ['alex@alexkoppel.com']
  s.homepage    = 'https://github.com/arsduo/batch_api'
  s.summary     = 'A RESTful Batch API for Rack'
  s.description = 'A Batch API plugin that provides a RESTful syntax, allowing clients to make any ' \
                  'number of REST calls with a single HTTP request.'

  s.files = Dir['{app,config,db,lib}/**/*'] + %w[MIT-LICENSE Rakefile changelog.md readme.md]
  s.test_files = Dir['spec/**/*']

  s.required_ruby_version = '3.2.2'

  s.add_runtime_dependency('middleware', '~> 0.1')
  s.add_runtime_dependency('multi_json', '~> 1.15')
  s.add_runtime_dependency('parallel', '~> 1.22')
end
