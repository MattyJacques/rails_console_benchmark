# frozen_string_literal: true

require 'terminal-table'

module RailsConsoleBenchmark
  # Formats and displays benchmark results as a table in the console.
  class Formatter
    def self.display(result)
      wall_times = result[:wall_times_ms]
      single = wall_times.length == 1

      if single
        rows = [
          ['Wall Time (ms)', wall_times.first],
          ['SQL Queries', result[:sql_queries].nil? ? 'N/A' : result[:sql_queries].first],
          ['Allocated Memory', format_bytes(result[:allocated_memory])],
          ['Retained Memory', format_bytes(result[:retained_memory])]
        ]

        puts Terminal::Table.new(headings: %w[Metric Value], rows: rows)
      else
        sql = result[:sql_queries]

        rows = [
          aggregate_row('Wall Time (ms)', wall_times),
          sql.nil? ? ['SQL Queries', 'N/A', 'N/A', 'N/A', 'N/A'] : aggregate_row('SQL Queries', sql),
          memory_row('Allocated Memory', result[:allocated_memory]),
          memory_row('Retained Memory', result[:retained_memory])
        ]

        puts Terminal::Table.new(headings: %w[Metric Min Max Mean Total], rows: rows)
      end
    end

    def self.aggregate_row(label, values)
      total = values.sum
      [
        label,
        values.min,
        values.max,
        (total.to_f / values.length).round(3),
        total.round(3)
      ]
    end
    private_class_method :aggregate_row

    def self.memory_row(label, bytes)
      formatted = format_bytes(bytes)
      [label, formatted, formatted, formatted, formatted]
    end
    private_class_method :memory_row

    def self.format_bytes(bytes)
      return '0 B' if bytes.zero?

      units = %w[B KB MB GB]
      exp = (Math.log(bytes) / Math.log(1024)).floor
      exp = [exp, units.length - 1].min
      format('%.2f %s', bytes.to_f / (1024**exp), units[exp])
    end
    private_class_method :format_bytes
  end
end
