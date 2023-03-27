# frozen_string_literal: true

require 'spec_helper'

describe BatchApi::Processor::Sequential do

  let(:app) { instance_double(Sinatra::Base, call: double) }
  let(:sequential) { described_class.new(app) }

  describe '#call' do
    let(:call_results) { Array.new(3) { |i| "called #{i}" } }
    let(:env) do
      {
        ops: Array.new(3) { |i| "op #{i}" },
      }
    end
    let(:op_middleware) { instance_double(BatchApi::RackMiddleware, call: {}) }

    before do
      allow(BatchApi::InternalMiddleware)
        .to receive(:operation_stack).and_return(op_middleware)
      allow(op_middleware).to receive(:call).and_return(*call_results)
    end

    it 'creates an operation middleware stack and calls it for each op' do
      env[:ops].each do |op|
        expect(op_middleware).to receive(:call)
          .with(hash_including(op:)).ordered
      end
      sequential.call(env)
    end

    it 'includes the rest of the env in the calls' do
      expect(op_middleware).to receive(:call)
        .with(hash_including(env)).exactly(3).times
      sequential.call(env)
    end

    it 'returns the results of the calls' do
      expect(sequential.call(env)).to eq(call_results)
    end
  end
end
