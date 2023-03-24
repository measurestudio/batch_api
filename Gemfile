source "http://rubygems.org"

# Declare your gem's dependencies in batch_api.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :development, :test do
  gem 'faker'
  gem 'test-unit'
  gem 'timecop'
  gem 'debugger', :platforms => [:mri_19]
  gem 'byebug', :platforms => [:mri_20, :mri_21]
  gem 'pry'

  # testing the request infrastructure
  gem "sinatra"
  gem "rspec"
  gem "rack-contrib"
  gem "rake"
  gem "activesupport"
  gem "rack-test"
end
