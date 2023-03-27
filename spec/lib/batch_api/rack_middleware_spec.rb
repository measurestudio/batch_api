# frozen_string_literal: true

require 'spec_helper'

describe BatchApi::RackMiddleware do
  describe '#initialize' do
    it 'allows access to the BatchApi configuration' do
      limit = rand * 100
      described_class.new(instance_double(Sinatra::Base)) do |conf|
        conf.limit = limit
      end
      expect(BatchApi.config.limit).to eq(limit)
    end
  end

  describe '#call' do
    let(:endpoint) { '/foo/bar' }
    let(:verb) { 'run' }
    let(:app) { instance_double(Sinatra::Base) }

    let(:middleware) do
      described_class.new(app) do |conf|
        conf.endpoint = endpoint
        conf.verb = verb
      end
    end

    context "when it's a batch call" do
      let(:env) do
        {
          'PATH_INFO' => endpoint,
          'REQUEST_METHOD' => verb.upcase,
          # other stuff
          'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
          'GATEWAY_INTERFACE' => 'CGI/1.1',
          'QUERY_STRING' => '',
          'REMOTE_ADDR' => '127.0.0.1',
          'REMOTE_HOST' => '1035.spotilocal.com',
          'REQUEST_URI' => 'http://localhost:3000/batch',
          'SCRIPT_NAME' => '',
          'rack.input' => StringIO.new,
          'rack.errors' => StringIO.new,
          'SERVER_NAME' => 'localhost',
          'SERVER_PORT' => '3000',
          'SERVER_PROTOCOL' => 'HTTP/1.1',
          'SERVER_SOFTWARE' => 'WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)',
          'HTTP_USER_AGENT' => 'curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5',
          'HTTP_HOST' => 'localhost:3000',
        }
      end

      let(:request) { Rack::Request.new(env) }
      let(:result) { { a: 2, b: { c: 3 } } }
      let(:processor) { instance_double(BatchApi::Processor, execute!: result) }

      before do
        allow(BatchApi::Processor).to receive(:new).and_return(processor)
      end

      context 'with a successful set of calls' do
        it 'returns the JSON-encoded result as the body' do
          output = middleware.call(env)
          expect(output[2]).to eq([MultiJson.dump(result)])
        end

        it 'returns a 200' do
          expect(middleware.call(env)[0]).to eq(200)
        end

        it 'sets the content type' do
          expect(middleware.call(env)[1]).to include('Content-Type' => 'application/json')
        end
      end

      context 'with BatchApi errors' do
        it 'returns a rendered ErrorWrapper' do
          err = StandardError.new
          result = double
          error = instance_double(BatchApi::ErrorWrapper, render: result)
          allow(BatchApi::Processor).to receive(:new).and_raise(err)
          allow(BatchApi::ErrorWrapper).to receive(:new).with(err).and_return(
            error
          )
          expect(middleware.call(env)).to eq(result)
        end
      end
    end

    context "when it's not a batch request" do
      let(:env) do
        {
          'PATH_INFO' => '/not/batch',
          'REQUEST_METHOD' => verb.upcase,
        }
      end

      it 'just calls the app onward and returns the result' do
        expect(app).to receive(:call)
        middleware.call(env)
      end
    end
  end
end
