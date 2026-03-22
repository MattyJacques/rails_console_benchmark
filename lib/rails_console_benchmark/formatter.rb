# frozen_string_literal: true

require 'terminal-table'

module RailsConsoleBenchmark
  # Formats and displays benchmark results as a table in the console.
  class Formatter
    def self.display(result)
      wall_times = result[:wall_times_ms]
      headings, rows = wall_times.length == 1 ? single_result(result) : aggregate_result(result)
      puts Terminal::Table.new(headings: headings, rows: rows)
    end

    def self.single_result(result)
      rows = [
        ['Wall Time (ms)', result[:wall_times_ms].first],
        sql_row(result[:sql_queries], single: true),
        ['Allocated Memory', format_bytes(result[:allocated_memory])],
        ['Retained Memory', format_bytes(result[:retained_memory])]
      ]
      [%w[Metric Value], rows]
    end
    private_class_method :single_result

    def self.aggregate_result(result)
      rows = [
        aggregate_row('Wall Time (ms)', result[:wall_times_ms]),
        sql_row(result[:sql_queries]),
        memory_row('Allocated Memory', result[:allocated_memory]),
        memory_row('Retained Memory', result[:retained_memory])
      ]
      [%w[Metric Min Max Mean Total], rows]
    end
    private_class_method :aggregate_result

    def self.sql_row(sql_queries, single: false)
      if sql_queries.nil?
        single ? ['SQL Queries', 'N/A'] : ['SQL Queries', *(['N/A'] * 4)]
      elsif single
        ['SQL Queries', sql_queries.first]
      else
        aggregate_row('SQL Queries', sql_queries)
      end
    end
    private_class_method :sql_row

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
      [label, *([formatted] * 4)]
    end
    private_class_method :memory_row

    def self.format_bytes(bytes)
      return '0 B' if bytes.zero?

      units = %w[B KB MB GB]
      exp = (Math.log(bytes) / Math.log(1024)).floor
      exp = [exp, units.length - 1].min
      format('%<value>.2f %<unit>s', value: bytes.to_f / (1024**exp), unit: units[exp])
    end
    private_class_method :format_bytes
  end
end
