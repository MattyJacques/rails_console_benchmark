# frozen_string_literal: true

RSpec.describe RailsConsoleBenchmark do
  it 'has a version number' do
    expect(RailsConsoleBenchmark::VERSION).not_to be_nil
  end

  it 'version is a string' do
    expect(RailsConsoleBenchmark::VERSION).to be_a(String)
  end

  it 'version matches semantic versioning format' do
    expect(RailsConsoleBenchmark::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end
end
