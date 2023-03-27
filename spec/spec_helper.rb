# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'test'

require 'rspec'
require 'faker'
require 'timecop'
require 'active_support'

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
