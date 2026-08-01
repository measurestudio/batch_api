# frozen_string_literal: true

module BatchApi
  # Internal: observes the time operations spend waiting to start and tracks
  # the number of operations currently executing in this Ruby process.
  class OperationTelemetry
    @active_operations = 0
    @mutex = Mutex.new

    class << self
      def operation_started
        @mutex.synchronize { @active_operations += 1 }
      end

      def operation_finished
        @mutex.synchronize { @active_operations -= 1 }
      end
    end

    def initialize(batch_size, observer: BatchApi.config.operation_queue_observer)
      @batch_size = batch_size
      @observer = observer
      return unless @observer

      @enqueued_at = monotonic_time
      notify_observer(:batch_started, batch_size: @batch_size)
    end

    def observe
      return yield unless @observer

      active_operations = operation_started
      yield
    ensure
      operation_finished if active_operations
    end

    private

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def operation_started
      started_at = monotonic_time
      active_operations = self.class.operation_started
      notify_observer(
        :operation_started,
        queue_duration: started_at - @enqueued_at,
        active_operations:
      )
      active_operations
    end

    def operation_finished
      active_operations = self.class.operation_finished
      notify_observer(:operation_finished, active_operations:)
    end

    def notify_observer(event, payload)
      @observer.call(event, payload.freeze)
    rescue StandardError
      # Observability must never change request behavior.
      nil
    end
  end
end
