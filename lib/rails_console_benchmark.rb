# frozen_string_literal: true

require_relative "rails_console_benchmark/version"
require_relative "rails_console_benchmark/formatter"
require_relative "rails_console_benchmark/tracker"
require_relative "rails_console_benchmark/railtie" if defined?(Rails::Railtie)

module RailsConsoleBenchmark
end
