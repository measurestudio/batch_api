# frozen_string_literal: true

module BatchApi
  class Processor
    class Parallel
      # Public: initialize with the app.
      def initialize(app)
        @app = app
      end

      # Returns an array of BatchApi::Response objects.
      def call(env)
        ::Parallel.map(env[:ops], in_threads: BatchApi.config.processes) do |op|
          local_env = BatchApi::Utils.deep_dup(env)
          local_env[:op] = op

          # execute the individual request inside the operation-specific
          # middeware, then clear out the current op afterward
          middleware = InternalMiddleware.operation_stack
          middleware.call(local_env).tap { |_r| env.delete(:op) }
        end
      end
    end
  end
end
