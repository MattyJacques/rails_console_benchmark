# frozen_string_literal: true

require "memory_profiler"

module ConsoleBenchmark
  def self.measure(&block)
    sql_count = 0
    memory_report = nil
    wall_time = nil

    if defined?(ActiveSupport::Notifications)
      subscriber = ->(*, payload) {
        next if payload[:name]&.start_with?("SCHEMA", "CACHE")

        sql_count += 1
      }

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        memory_report = MemoryProfiler.report do
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          block.call
          wall_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        end
      end
    else
      memory_report = MemoryProfiler.report do
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        block.call
        wall_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end
    end

    result = {
      wall_time_ms: (wall_time * 1000).round(3),
      sql_queries: defined?(ActiveSupport::Notifications) ? sql_count : nil,
      allocated_memory: memory_report.total_allocated_memsize,
      retained_memory: memory_report.total_retained_memsize
    }

    RailsConsoleBenchmark::Formatter.display(result)
    result
  end
end
