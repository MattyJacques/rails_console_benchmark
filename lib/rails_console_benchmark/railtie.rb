# frozen_string_literal: true

module RailsConsoleBenchmark
  # Registers RailsConsoleBenchmark with the Rails lifecycle.
  # Automatically loaded when Rails::Railtie is available so the gem
  # participates in the Rails boot process. Console-specific hooks
  # (e.g. helpers, welcome messages) can be added here in future.
  class Railtie < Rails::Railtie
  end
end
