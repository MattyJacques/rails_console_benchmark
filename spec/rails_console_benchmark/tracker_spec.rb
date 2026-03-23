# frozen_string_literal: true

RSpec.describe RailsConsoleBenchmark::Tracker do
  let(:memory_report) do
    instance_double(MemoryProfiler::Results,
                    total_allocated_memsize: 1024,
                    total_retained_memsize: 512)
  end

  before do
    allow(MemoryProfiler).to receive(:report).and_yield.and_return(memory_report)
    allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0)
    allow(RailsConsoleBenchmark::Formatter).to receive(:display)
  end

  describe '.measure' do
    it 'raises ArgumentError when iterations is less than 1' do
      expect { described_class.measure(0) { nil } }.to raise_error(ArgumentError, 'iterations must be >= 1')
    end

    it 'raises ArgumentError for negative iterations' do
      expect { described_class.measure(-5) { nil } }.to raise_error(ArgumentError, 'iterations must be >= 1')
    end

    it 'calls Formatter.display with results' do
      described_class.measure(1) { nil }
      expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
    end
  end

  describe '#initialize' do
    it 'raises ArgumentError when iterations < 1' do
      expect { described_class.new(0) }.to raise_error(ArgumentError, 'iterations must be >= 1')
    end

    it 'raises ArgumentError for negative iterations' do
      expect { described_class.new(-1) }.to raise_error(ArgumentError, 'iterations must be >= 1')
    end

    it 'accepts iterations = 1' do
      expect { described_class.new(1) }.not_to raise_error
    end

    it 'accepts iterations > 1' do
      expect { described_class.new(3) }.not_to raise_error
    end
  end

  describe '#measure' do
    context 'without ActiveSupport::Notifications (non-Rails)' do
      it 'passes nil for sql_queries to Formatter' do
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(sql_queries: nil))
      end

      it 'converts wall time to milliseconds' do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0)
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(wall_times_ms: [1000.0]))
      end

      it 'rounds wall time to 3 decimal places' do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 1.23456789)
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(wall_times_ms: [1234.568]))
      end

      it 'passes allocated memory from MemoryProfiler' do
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(allocated_memory: 1024))
      end

      it 'passes retained memory from MemoryProfiler' do
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(retained_memory: 512))
      end

      it 'only runs memory profiling on the first iteration' do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0, 2.0, 3.0, 4.0, 5.0)
        described_class.measure(3) { nil }
        expect(MemoryProfiler).to have_received(:report).once
      end

      it 'collects a wall time per iteration' do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0, 2.0, 3.0, 4.0, 5.0)
        described_class.measure(3) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(wall_times_ms: [1000.0, 1000.0, 1000.0]))
      end

      it 'executes the block on every iteration' do
        call_count = 0
        allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0, 2.0, 3.0)
        described_class.measure(2) { call_count += 1 }
        expect(call_count).to eq(2)
      end
    end

    context 'with ActiveSupport::Notifications (Rails)' do
      let(:notifications) { Module.new }

      def stub_sql_events(*names)
        allow(notifications).to receive(:subscribed) do |subscriber, _event, &blk|
          names.each { |name| subscriber.call('sql.active_record', nil, nil, nil, { name: name }) }
          blk.call
        end
      end

      before do
        stub_const('ActiveSupport::Notifications', notifications)

        allow(notifications).to receive(:subscribed) do |_subscriber, _event, &blk|
          blk.call
        end
      end

      it 'passes zero SQL queries when no events fire' do
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(sql_queries: [0]))
      end

      it 'counts SQL query notifications' do
        stub_sql_events('SELECT users', 'SELECT posts')
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(sql_queries: [2]))
      end

      it 'ignores SCHEMA queries' do
        stub_sql_events('SCHEMA', 'SELECT users')
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(sql_queries: [1]))
      end

      it 'ignores CACHE queries' do
        stub_sql_events('CACHE', 'SELECT posts')
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(sql_queries: [1]))
      end

      it 'ignores queries whose name starts with SCHEMA (prefix match)' do
        stub_sql_events('SCHEMA information')
        described_class.measure(1) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(sql_queries: [0]))
      end

      it 'handles a nil query name without error' do
        stub_sql_events(nil)
        expect { described_class.measure(1) { nil } }.not_to raise_error
      end

      it 'collects per-iteration SQL counts for multi-iteration runs' do
        allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0, 2.0, 3.0)
        stub_sql_events('SELECT')
        described_class.measure(2) { nil }
        expect(RailsConsoleBenchmark::Formatter).to have_received(:display)
          .with(hash_including(sql_queries: [1, 1]))
      end

      it 'subscribes to the sql.active_record event' do
        described_class.measure(1) { nil }
        expect(notifications).to have_received(:subscribed)
          .with(anything, 'sql.active_record')
      end
    end
  end
end
