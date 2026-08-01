# frozen_string_literal: true

require 'spec_helper'

describe BatchApi::Processor::Parallel do
  let(:parallel) { described_class.new(instance_double(Sinatra::Base)) }
  let(:env) { { ops: Array.new(3) { |index| "op #{index}" } } }
  let(:middleware) { instance_double(BatchApi::RackMiddleware) }

  before do
    allow(BatchApi::InternalMiddleware).to receive(:operation_stack).and_return(middleware)
    allow(middleware).to receive(:call) { |local_env| "called #{local_env[:op]}" }
  end

  it 'executes each operation and preserves result order' do
    expect(parallel.call(env)).to eq(['called op 0', 'called op 1', 'called op 2'])
  end

  it 'observes each queued operation with the batch size' do
    events = Queue.new
    BatchApi.config.operation_queue_observer = proc { |event, payload| events << [event, payload] }

    parallel.call(env)

    observed = Array.new(7) { events.pop }
    expect(observed.count { |event, _payload| event == :batch_started }).to eq(1)
    expect(observed.count { |event, _payload| event == :operation_started }).to eq(3)
    expect(observed.count { |event, _payload| event == :operation_finished }).to eq(3)
    expect(observed.first).to eq([:batch_started, { batch_size: 3 }])
  end
end
