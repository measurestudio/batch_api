# frozen_string_literal: true

module BatchApi
  # Public: a response from an internal operation in the Batch API.
  # It contains all the details that are needed to describe the call's
  # outcome.
  class Response
    # Public: the attributes of the HTTP response.
    attr_accessor :status, :body, :headers

    # Public: create a new response representation from a Rack-compatible
    # response (e.g. [status, headers, response_object]).
    def initialize(response)
      @status, @headers = *response
      @body = process_body(response[2])
    end

    # Public: convert the response to JSON.  nil values are ignored.
    def to_h(_options = {})
      {}.tap do |result|
        result[:body] = @body unless @body.nil?
        result[:headers] = @headers unless @headers.nil?
        result[:status] = @status unless @status.nil?
      end
    end

    private

    def process_body(body_pieces)
      # bodies have to respond to .each, but may otherwise
      # not be suitable for JSON serialization
      # (I'm looking at you, ActionDispatch::Response)
      # so turn it into a string
      body_pieces.join
    end
  end
end
