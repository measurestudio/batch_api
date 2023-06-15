# frozen_string_literal: true

require 'batch_api/response'

module BatchApi
  # Public: an individual batch operation.
  module Operation
    class Rack
      attr_accessor :method, :url, :params, :headers, :env, :app, :result, :options

      # Public: create a new Batch Operation given the specifications for a batch
      # operation (as defined above) and the request environment for the main
      # batch request.
      def initialize(op, base_env, app)
        @op = op

        @method = op['method'] || 'GET'
        @url = op['url']
        @params = op['params'] || {}
        @headers = op['headers'] || {}
        @body = op['body'] || ''
        @options = op

        ensure_method_and_url!

        @app = app
        # deep_dup to avoid unwanted changes across requests
        @env = BatchApi::Utils.deep_dup(base_env)
      end

      # Execute a batch request, returning a BatchResponse object.  If an error
      # occurs, it returns the same results as Rails would.
      def execute
        process_env

        begin
          response = @app.call(@env)
        rescue StandardError => e
          response = BatchApi::ErrorWrapper.new(e).render
        end
        BatchApi::Response.new(response)
      end

      # Internal: customize the request environment.  This is currently done
      # manually and feels clunky and brittle, but is mostly likely fine, though
      # there are one or two environment parameters not yet adjusted.
      def process_env
        apply_headers
        apply_method
        apply_path_and_query_string
        apply_form
        apply_body
      end

      def apply_headers
        local_headers = (@headers || {}).inject({}) do |heads, (k, v)|
          heads.tap { |h| h["HTTP_#{k.tr('-', '_').upcase}"] = v }
        end
        # preserve original headers unless explicitly overridden
        @env.merge!(local_headers)
      end

      def apply_method
        @env[::Rack::REQUEST_METHOD] = @method.upcase
      end

      def apply_path_and_query_string
        uri = URI.parse(@url)

        @env['REQUEST_URI'] = @env['REQUEST_URI'].gsub(/#{BatchApi.config.endpoint}.*/, @url) if @env['REQUEST_URI']
        @env[::Rack::REQUEST_PATH] = uri.path
        @env['ORIGINAL_FULLPATH'] = @env[::Rack::PATH_INFO] = @url

        qs = extract_query_string(uri)
        @env[::Rack::RACK_REQUEST_QUERY_STRING] = @env[::Rack::QUERY_STRING] = qs
      end

      def apply_form
        uri = URI.parse(@url)
        @env[::Rack::RACK_REQUEST_FORM_HASH] = @params
        @env[::Rack::RACK_REQUEST_FORM_INPUT] = @env[::Rack::RACK_INPUT]
        @env[::Rack::RACK_REQUEST_QUERY_HASH] = if @method == 'GET'
                                                  ::Rack::Utils.parse_nested_query(uri.query).merge(@params)
                                                end
      end

      def apply_body
        return unless %w[POST PUT PATCH].include?(@method)
        return if @body.empty?

        @env.update(
          ::Rack::RACK_INPUT => StringIO.new(@body),
          ::Rack::RACK_REQUEST_FORM_INPUT => StringIO.new(@body),
          ::Rack::RACK_REQUEST_FORM_HASH => @params.merge(MultiJson.load(@body))
        )
      end

      def extract_query_string(uri)
        if @method == 'GET'
          get_params = ::Rack::Utils.parse_nested_query(uri.query).merge(@params)
          CGI.escape(::Rack::Utils.build_nested_query(get_params))
        else
          uri.query
        end
      end

      def ensure_method_and_url!
        return if @method && @url
        raise Errors::MalformedOperationError,
          "BatchAPI operation must include method (received #{@method.inspect}) " \
          "and url (received #{@url.inspect})"
      end
    end
  end
end
