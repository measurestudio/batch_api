# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'test'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter %r{^/spec/}
    enable_for_subprocesses true
    at_fork do |pid|
      # This needs a unique name so it won't be ovewritten
      SimpleCov.command_name "#{SimpleCov.command_name} (subprocess: #{pid})"
      # be quiet, the parent process will be in charge of output and checking coverage totals
      SimpleCov.print_error_status = false
      SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
      SimpleCov.minimum_coverage 0
      # start
      SimpleCov.start
    end
  end
end

require 'rspec'
require 'faker'
require 'timecop'

require_relative '../lib/batch_api'
# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.color = true

  config.before do
    BatchApi.config.limit = 20
    BatchApi.config.endpoint = '/batch'
    BatchApi.config.verb = :post
  end
end
