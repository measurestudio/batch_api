# frozen_string_literal: true

require 'spec_helper'
require 'batch_api/operation_telemetry'

describe BatchApi::OperationTelemetry do
  let(:event_queues) do
    {
      batch_started: Queue.new,
      operation_started: Queue.new,
      operation_finished: Queue.new,
    }
  end
  let(:queueing_observer) { proc { |event, payload| event_queues[event] << payload } }

  def observe_concurrently(telemetries, started_events, release)
    threads = telemetries.map do |telemetry|
      Thread.new { telemetry.observe { release.pop } }
    end
    observed = Array.new(telemetries.length) { started_events.pop }
    telemetries.length.times { release << true }
    threads.each(&:join)
    observed
  end

  def expected_lifecycle_events
    [
      [:batch_started, { batch_size: 3 }],
      [:operation_started, { queue_duration: 0.25, active_operations: 1 }],
      [:operation_finished, { active_operations: 0 }],
    ]
  end

  describe '#observe' do
    it 'reports the batch and operation lifecycle with monotonic queue duration' do
      events = []
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC).and_return(10.0, 10.25)

      observer = proc { |event, payload| events << [event, payload] }
      telemetry = described_class.new(3, observer:)
      telemetry.observe { :result }

      expect(events).to eq(expected_lifecycle_events)
    end

    it 'does not read the clock when no observer is configured' do
      expect(Process).not_to receive(:clock_gettime)

      expect(described_class.new(1).observe { :result }).to eq(:result)
    end

    it 'does not let observer failures break operation execution' do
      observer = proc { raise 'telemetry failed' }

      expect(described_class.new(1, observer:).observe { :result }).to eq(:result)
    end

    it 'counts concurrently active operations across batches' do
      release = Queue.new
      first = described_class.new(2, observer: queueing_observer)
      second = described_class.new(4, observer: queueing_observer)
      started = observe_concurrently([first, second], event_queues[:operation_started], release)
      batches = Array.new(2) { event_queues[:batch_started].pop }
      finished = Array.new(2) { event_queues[:operation_finished].pop }

      expect(batches.map { |event| event[:batch_size] }.sort).to eq([2, 4])
      expect(started.map { |event| event[:active_operations] }.sort).to eq([1, 2])
      expect(finished.map { |event| event[:active_operations] }.sort).to eq([0, 1])
    end

    it 'decrements the active count when operation execution fails' do
      observer = proc {}
      expect do
        described_class.new(1, observer:).observe { raise 'operation failed' }
      end.to raise_error('operation failed')

      events = []
      observer = proc { |event, payload| events << payload if event == :operation_started }
      described_class.new(1, observer:).observe { :result }
      expect(events.first[:active_operations]).to eq(1)
    end
  end
end
