require 'rspec'
require 'faker'
require 'timecop'
require 'active_support'

require_relative '../lib/batch_api'
# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end

RSpec.configure do |config|
  config.color = true

  config.before :each do
    BatchApi.config.limit = 20
    BatchApi.config.endpoint = "/batch"
    BatchApi.config.verb = :post
  end
end
