# frozen_string_literal: true

source 'http://rubygems.org'

# Declare your gem's dependencies in batch_api.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :development, :test do
  gem 'byebug', platforms: %i[mri_20 mri_21]
  gem 'debugger', platforms: [:mri_19]
  gem 'faker'
  gem 'pry'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
  gem 'test-unit'
  gem 'timecop'

  # testing the request infrastructure
  gem 'activesupport'
  gem 'rack-contrib'
  gem 'rack-test'
  gem 'rake'
  gem 'rspec'
  gem 'sinatra'
end
