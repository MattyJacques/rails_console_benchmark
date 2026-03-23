# frozen_string_literal: true

require 'memory_profiler'

module RailsConsoleBenchmark
  # Measures wall time, SQL query counts, and memory usage for a block of code.
  class Tracker
    def self.measure(iterations = 1, &block)
      new(iterations).measure(&block)
    end

    def initialize(iterations = 1)
      raise ArgumentError, 'iterations must be >= 1' if iterations < 1

      @iterations = iterations
      @track_sql = defined?(ActiveSupport::Notifications)
    end

    def measure(&block)
      wall_times, sql_counts, memory_report = collect_measurements(&block)
      RailsConsoleBenchmark::Formatter.display(
        wall_times_ms: wall_times,
        sql_queries: sql_counts,
        allocated_memory: memory_report.total_allocated_memsize,
        retained_memory: memory_report.total_retained_memsize
      )
    end

    private

    def collect_measurements(&block)
      results = (0...@iterations).map { |i| run_iteration(i, &block) }
      wall_times = results.map { |wt, *| (wt * 1000).round(3) }
      sql_counts = results.map { |_wt, sql, *| sql }
      [wall_times, @track_sql ? sql_counts : nil, results.first.last]
    end

    def run_iteration(index, &block)
      result, sql_count = with_sql_tracking do
        if index.zero?
          timed_with_memory_profile { start_time_and_call(&block) }
        else
          [start_time_and_call(&block), nil]
        end
      end
      wall_time, report = result
      [wall_time, sql_count, report]
    end

    def with_sql_tracking(&block)
      return [block.call, nil] unless @track_sql

      sql_count = 0
      subscriber = lambda { |*, payload|
        next if payload[:name]&.start_with?('SCHEMA', 'CACHE')

        sql_count += 1
      }
      result = ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record', &block)
      [result, sql_count]
    end

    def timed_with_memory_profile(&block)
      wall_time = nil
      report = MemoryProfiler.report { wall_time = block.call }
      [wall_time, report]
    end

    def start_time_and_call(&block)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      block.call
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end
  end
end
