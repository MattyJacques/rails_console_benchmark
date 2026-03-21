# frozen_string_literal: true

require "terminal-table"

module RailsConsoleBenchmark
  class Formatter
    def self.display(result)
      rows = [
        ["Wall Time (ms)", result[:wall_time_ms]],
        ["SQL Queries", result[:sql_queries].nil? ? "N/A" : result[:sql_queries]],
        ["Allocated Memory", format_bytes(result[:allocated_memory])],
        ["Retained Memory", format_bytes(result[:retained_memory])]
      ]

      table = Terminal::Table.new(
        headings: ["Metric", "Value"],
        rows: rows
      )

      puts table
    end

    private_class_method :format_bytes
    def self.format_bytes(bytes)
      return "0 B" if bytes.zero?

      units = ["B", "KB", "MB", "GB"]
      exp = (Math.log(bytes) / Math.log(1024)).floor
      exp = [exp, units.length - 1].min
      "%.2f %s" % [bytes.to_f / (1024**exp), units[exp]]
    end
  end
end
