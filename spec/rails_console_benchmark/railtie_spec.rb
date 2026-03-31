# frozen_string_literal: true

RSpec.describe 'RailsConsoleBenchmark::Railtie' do
  let(:railtie_path) { File.expand_path('../../lib/rails_console_benchmark/railtie.rb', __dir__) }

  context 'when Rails::Railtie is not defined' do
    it 'does not define RailsConsoleBenchmark::Railtie' do
      expect(defined?(RailsConsoleBenchmark::Railtie)).to be_nil
    end
  end

  context 'when Rails::Railtie is defined' do
    let(:railtie_base) { Class.new }

    before do
      stub_const('Rails::Railtie', railtie_base)
      # Register constant with stub_const so RSpec handles cleanup automatically.
      # Pre-stub with a subclass of railtie_base so the load can reopen the class
      # without triggering a superclass mismatch.
      stub_const('RailsConsoleBenchmark::Railtie', Class.new(railtie_base))
      load railtie_path
    end

    it 'defines RailsConsoleBenchmark::Railtie' do
      expect(defined?(RailsConsoleBenchmark::Railtie)).to eq('constant')
    end

    it 'inherits from Rails::Railtie' do
      expect(RailsConsoleBenchmark::Railtie.superclass).to eq(railtie_base)
    end
  end
end
