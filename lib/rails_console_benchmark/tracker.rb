# frozen_string_literal: true

require 'memory_profiler'

module RailsConsoleBenchmark
  # Measures wall time, SQL query counts, and memory usage for a block of code.
  class Tracker
    def self.measure(iterations = 1, &)
      raise ArgumentError, 'iterations must be >= 1' if iterations < 1

      wall_times, sql_counts, memory_report = collect_measurements(iterations, &)
      RailsConsoleBenchmark::Formatter.display(
        wall_times_ms: wall_times,
        sql_queries: sql_counts,
        allocated_memory: memory_report.total_allocated_memsize,
        retained_memory: memory_report.total_retained_memsize
      )
    end

    def self.collect_measurements(iterations, &block)
      track_sql = defined?(ActiveSupport::Notifications)
      results = (0...iterations).map { |i| run_iteration(i, track_sql, &block) }
      wall_times = results.map { |wt, *| (wt * 1000).round(3) }
      sql_counts = results.map { |_wt, sql, *| sql }
      [wall_times, track_sql ? sql_counts : nil, results.first.last]
    end
    private_class_method :collect_measurements

    def self.run_iteration(index, track_sql, &block)
      result, sql_count = with_sql_tracking(track_sql) do
        if index.zero?
          timed_with_memory_profile { start_time_and_call(&block) }
        else
          [start_time_and_call(&block), nil]
        end
      end
      wall_time, report = result
      [wall_time, sql_count, report]
    end
    private_class_method :run_iteration

    def self.with_sql_tracking(enabled, &block)
      return [block.call, nil] unless enabled

      sql_count = 0
      subscriber = lambda { |*, payload|
        next if payload[:name]&.start_with?('SCHEMA', 'CACHE')

        sql_count += 1
      }
      result = ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record', &block)
      [result, sql_count]
    end
    private_class_method :with_sql_tracking

    def self.timed_with_memory_profile(&block)
      wall_time = nil
      report = MemoryProfiler.report { wall_time = block.call }
      [wall_time, report]
    end
    private_class_method :timed_with_memory_profile

    def self.start_time_and_call(&block)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      block.call
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end
    private_class_method :start_time_and_call
  end
end
