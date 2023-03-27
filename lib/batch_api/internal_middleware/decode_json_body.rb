# frozen_string_literal: true

module BatchApi
  module InternalMiddleware
    # Public: a middleware that decodes the body of any individual batch
    # operation if it's JSON.
    class DecodeJsonBody
      # Public: initialize the middleware.
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env).tap do |result|
          result.body = MultiJson.load(result.body) if should_decode?(result)
        end
      end

      private

      def should_decode?(result)
        result.headers['Content-Type'] =~ %r{^application/json} && !result.body&.empty?
      end
    end
  end
end
