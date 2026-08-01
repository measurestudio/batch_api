# frozen_string_literal: true

require 'batch_api/internal_middleware'

module BatchApi
  # Public: configuration options.
  # Currently, you can set:
  # - endpoint: (URL) through which the Batch API will be exposed (default
  # "/batch)
  # - verb: through which it's accessed (default "POST")
  # - limit: how many requests can be processed in a single request
  # (default 50)
  #
  # There are also two middleware-related options -- check out middleware.rb
  # for more information.
  # - global_middleware: any middlewares to use round the entire batch request
  # (such as authentication, etc.)
  # - per_op_middleware: any middlewares to run around each individual request
  # (adding headers, decoding JSON, etc.)
  # - operation_queue_observer: an optional callable invoked for batch and
  # operation lifecycle events with queue and concurrency telemetry
  CONFIGURATION_OPTIONS = {
    verb: :post,
    endpoint: '/batch',
    limit: 50,
    batch_middleware: InternalMiddleware::DEFAULT_BATCH_MIDDLEWARE,
    operation_middleware: InternalMiddleware::DEFAULT_OPERATION_MIDDLEWARE,
    processes: 4,
    operation_queue_observer: nil,
  }.freeze

  # Batch API Configuration
  Configuration = Struct.new(*CONFIGURATION_OPTIONS.keys) do
    # Public: initialize a new configuration option and apply the defaults.
    def initialize
      super
      CONFIGURATION_OPTIONS.each { |k, v| self[k] = v }
    end
  end
end
