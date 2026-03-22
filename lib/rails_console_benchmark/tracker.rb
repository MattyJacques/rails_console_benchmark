# frozen_string_literal: true

require "memory_profiler"

module ConsoleBenchmark
  def self.measure(iterations = 1, &block)
    raise ArgumentError, "iterations must be >= 1" if iterations < 1

    wall_times = []
    sql_counts = []
    memory_report = nil

    iterations.times do |i|
      sql_count = 0
      wall_time = nil

      if defined?(ActiveSupport::Notifications)
        subscriber = ->(*, payload) {
          next if payload[:name]&.start_with?("SCHEMA", "CACHE")

          sql_count += 1
        }

        if i.zero?
          ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
            memory_report = MemoryProfiler.report do
              wall_time = start_time_and_call(&block)
            end
          end
        else
          ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
            wall_time = start_time_and_call(&block)
          end
        end
      else
        if i.zero?
          memory_report = MemoryProfiler.report do
            wall_time = start_time_and_call(&block)
          end
        else
          wall_time = start_time_and_call(&block)
        end
      end

      wall_times << (wall_time * 1000).round(3)
      sql_counts << sql_count
    end

    result = {
      wall_times_ms: wall_times,
      sql_queries: defined?(ActiveSupport::Notifications) ? sql_counts : nil,
      allocated_memory: memory_report.total_allocated_memsize,
      retained_memory: memory_report.total_retained_memsize
    }

    RailsConsoleBenchmark::Formatter.display(result)
  end

  def self.start_time_and_call(&block)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    block.call
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end
  private_class_method :start_time_and_call
end
