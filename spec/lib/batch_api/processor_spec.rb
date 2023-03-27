# frozen_string_literal: true

require 'spec_helper'

# TODO: This spec is pretty bad, maybe it'll be better served by integration testing
# TODO: Review with coverage
# rubocop:disable RSpec/MultipleMemoizedHelpers
# rubocop:disable RSpec/VerifiedDoubles
xdescribe BatchApi::Processor do
  let(:ops) { [{ 'url' => '/endpoint', 'method' => 'GET' }] }
  let(:options) { { 'sequential' => true } }
  let(:env) do
    {
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
      'GATEWAY_INTERFACE' => 'CGI/1.1',
      'PATH_INFO' => '/foo',
      'QUERY_STRING' => '',
      'REMOTE_ADDR' => '127.0.0.1',
      'REMOTE_HOST' => '1035.spotilocal.com',
      'REQUEST_METHOD' => 'REPORT',
      'REQUEST_URI' => 'http://localhost:3000/batch',
      'SCRIPT_NAME' => '',
      'rack.input' => StringIO.new,
      'rack.errors' => StringIO.new,
      'SERVER_NAME' => 'localhost',
      'SERVER_PORT' => '3000',
      'SERVER_PROTOCOL' => 'HTTP/1.1',
      'SERVER_SOFTWARE' => 'WEBrick/1.3.1 (Ruby/1.9.3/2012-02-16)',
      'HTTP_USER_AGENT' => 'curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21',
      'HTTP_HOST' => 'localhost:3000',
    }
  end

  let(:request) do
    Rack::Request.new(env).tap do |r|
      allow(r).to receive(:params).and_return({}.merge('ops' => ops).merge(options))
    end
  end
  let(:app) { double('application', call: [200, {}, ['foo']]) }
  let(:operation_klass) { double('op class') }
  let(:processor) { described_class.new(request, app, operation_klass:) }

  before do
    operation_objects = Array.new(3) { double('operation object') }
    operation_params = Array.new(3) do |i|
      double('raw operation').tap do |o|
        allow(operation_klass).to receive(:new)
          .with(o, env, app).and_return(operation_objects[i])
      end
    end
    request.params['ops'] = operation_params
  end

  describe '#initialize' do
    # this may be brittle...consider refactoring?
    it 'turns the ops params into processed operations at #ops' do
      operation_objects = Array.new(3) { double('operation object') }
      operation_params = Array.new(3) do |i|
        double('raw operation').tap do |o|
          allow(operation_klass).to receive(:new)
            .with(o, env, app).and_return(operation_objects[i])
        end
      end
      request.params['ops'] = operation_params
      expect(described_class.new(request, app, operation_klass:).ops).to eq(operation_objects)
    end

    it 'makes the options available' do
      expect(described_class.new(request, app, operation_klass:).options).to eq(options)
    end

    it 'makes the app available' do
      expect(described_class.new(request, app, operation_klass:).app).to eq(app)
    end

    context 'with error conditions' do
      it '(currently) throws an error if sequential is not true' do
        request.params.delete('sequential')
        expect do
          described_class.new(request, app, operation_klass:)
        end.to raise_exception(BatchApi::Errors::BadOptionError)
      end

      it 'raise a OperationLimitExceeded error if too many ops provided' do
        ops = Array.new((BatchApi.config.limit + 1).to_i) { |i| i }
        request.params['ops'] = ops
        expect do
          described_class.new(request, app, operation_klass:)
        end.to raise_exception(BatchApi::Errors::OperationLimitExceeded)
      end

      it 'raises a NoOperationError if operations.blank?' do
        request.params['ops'] = nil
        expect do
          described_class.new(request, app, operation_klass:)
        end.to raise_exception(BatchApi::Errors::NoOperationsError)
        request.params['ops'] = []
        expect do
          described_class.new(request, app, operation_klass:)
        end.to raise_exception(BatchApi::Errors::NoOperationsError)
      end
    end
  end

  describe '#strategy' do
    it 'returns BatchApi::Processor::Sequential' do
      expect(described_class.new(request, app, operation_klass:).strategy).to eq(BatchApi::Processor::Sequential)
    end
  end

  describe '#execute!' do
    let(:result) { double('result') }
    let(:stack) { double('stack', call: result) }
    let(:middleware_env) do
      ops = Array.new(3) { double('operation object') }
      Array.new(3) do |i|
        double('raw operation').tap do |o|
          allow(operation_klass).to receive(:new)
            .with(o, env, app).and_return(ops[i])
        end
      end
      {
        ops: processor.ops, # the processed Operation objects
        rack_env: env,
        rack_app: app,
        options:,
      }
    end

    before do
      allow(BatchApi::InternalMiddleware).to receive(:batch_stack).and_return(stack)
    end

    it 'calls an internal middleware stacks with the appropriate data' do
      expect(stack).to receive(:call).with(middleware_env)
      processor.execute!
    end

    it 'returns the formatted result of the strategy' do
      allow(stack).to receive(:call).and_return(stubby = double)
      expect(described_class.new(request, app, operation_klass:).execute!['results']).to eq(stubby)
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
# rubocop:enable RSpec/VerifiedDoubles
