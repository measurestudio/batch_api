# frozen_string_literal: true

require 'spec_helper'
require 'batch_api/processor/executor'

describe BatchApi::Processor::Executor do
  let(:app) { instance_double(Sinatra::Base, call: double) }
  let(:executor) { described_class.new(app) }
  let(:result) { {} }
  let(:op) { instance_double(BatchApi::Operation::Rack, execute: result) }
  let(:env) { { op: } }

  describe '#call' do
    it 'executes the operation' do
      expect(op).to receive(:execute)
      executor.call(env)
    end

    it 'returns the result' do
      expect(executor.call(env)).to eq(result)
    end
  end
end
