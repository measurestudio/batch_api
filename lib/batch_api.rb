require 'batch_api/configuration'
require 'batch_api/version'
require 'batch_api/utils'
require 'batch_api/processor'

require 'batch_api/internal_middleware'
require 'batch_api/rack_middleware'

require 'batch_api/error_wrapper'
require 'batch_api/batch_error'

module BatchApi

  # Public: access the main Batch API configuration object.
  #
  # Returns a BatchApi::Configuration instance
  def self.config
    @config ||= Configuration.new
  end
end
