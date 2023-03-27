# frozen_string_literal: true

module BatchApi
  class RackMiddleware
    def initialize(app, &block)
      @app = app
      yield BatchApi.config if block
    end

    def call(env)
      if batch_request?(env)
        process_request(env)
      else
        @app.call(env)
      end
    end

    def self.content_type
      { 'Content-Type' => 'application/json' }
    end

    private

    def process_request(env)
      request = Rack::Request.new(env)
      result = BatchApi::Processor.new(request, @app).execute!
      [200, self.class.content_type, [MultiJson.dump(result)]]
    rescue StandardError => e
      ErrorWrapper.new(e).render
    end

    def batch_request?(env)
      env['PATH_INFO'] == BatchApi.config.endpoint &&
        env['REQUEST_METHOD'] == BatchApi.config.verb.to_s.upcase
    end
  end
end
