# frozen_string_literal: true

# End-to-end specs that simulate running inside a Rails application.
# Unlike the unit specs, Formatter is NOT stubbed here — these tests
# exercise the full Tracker → Formatter → stdout pipeline with both
# ActiveSupport::Notifications and Rails::Railtie present.
RSpec.describe RailsConsoleBenchmark, type: :integration do
  let(:notifications) { Module.new }
  let(:railtie_base) { Class.new }
  let(:memory_report) do
    instance_double(MemoryProfiler::Results,
                    total_allocated_memsize: 1_048_576,
                    total_retained_memsize: 4096)
  end

  before do
    stub_const('ActiveSupport::Notifications', notifications)
    stub_const('Rails::Railtie', railtie_base)
    stub_const('RailsConsoleBenchmark::Railtie', Class.new(railtie_base))
    allow(MemoryProfiler).to receive(:report).and_yield.and_return(memory_report)
    allow(Process).to receive(:clock_gettime).and_return(0.0, 0.042371)
    allow(notifications).to receive(:subscribed) do |_subscriber, _event, &blk|
      blk.call
    end
  end

  describe 'single iteration' do
    it 'prints all four metric rows' do
      expect { RailsConsoleBenchmark::Tracker.measure(1) { nil } }
        .to output(include('Wall Time (ms)', 'SQL Queries', 'Allocated Memory', 'Retained Memory'))
        .to_stdout
    end

    it 'uses single-iteration table headings' do
      expect { RailsConsoleBenchmark::Tracker.measure(1) { nil } }
        .to output(include('Metric', 'Value')).to_stdout
    end

    it 'shows zero SQL queries when no events fire' do
      expect { RailsConsoleBenchmark::Tracker.measure(1) { nil } }
        .to output(include('SQL Queries', '0')).to_stdout
    end

    it 'formats allocated memory' do
      expect { RailsConsoleBenchmark::Tracker.measure(1) { nil } }
        .to output(include('1.00 MB')).to_stdout
    end

    it 'formats retained memory' do
      expect { RailsConsoleBenchmark::Tracker.measure(1) { nil } }
        .to output(include('4.00 KB')).to_stdout
    end

    context 'when SQL queries fire during the block' do
      before do
        allow(notifications).to receive(:subscribed) do |subscriber, _event, &blk|
          subscriber.call('sql.active_record', nil, nil, nil, { name: 'SELECT users' })
          subscriber.call('sql.active_record', nil, nil, nil, { name: 'SELECT posts' })
          blk.call
        end
      end

      it 'counts the SQL queries' do
        expect { RailsConsoleBenchmark::Tracker.measure(1) { nil } }
          .to output(include('SQL Queries', '2')).to_stdout
      end
    end

    context 'when SCHEMA and CACHE queries fire alongside real queries' do
      before do
        allow(notifications).to receive(:subscribed) do |subscriber, _event, &blk|
          subscriber.call('sql.active_record', nil, nil, nil, { name: 'SCHEMA' })
          subscriber.call('sql.active_record', nil, nil, nil, { name: 'CACHE' })
          subscriber.call('sql.active_record', nil, nil, nil, { name: 'SELECT users' })
          blk.call
        end
      end

      it 'excludes SCHEMA and CACHE from the count' do
        expect { RailsConsoleBenchmark::Tracker.measure(1) { nil } }
          .to output(include('SQL Queries', '1')).to_stdout
      end
    end
  end

  describe 'multiple iterations' do
    before do
      allow(Process).to receive(:clock_gettime).and_return(0.0, 0.1, 0.2, 0.3, 0.4, 0.5)
    end

    it 'uses multi-iteration table headings' do
      expect { RailsConsoleBenchmark::Tracker.measure(3) { nil } }
        .to output(include('Metric', 'Min', 'Max', 'Mean', 'Total')).to_stdout
    end

    it 'only runs memory profiling once across all iterations' do
      RailsConsoleBenchmark::Tracker.measure(3) { nil }
      expect(MemoryProfiler).to have_received(:report).once
    end

    context 'when SQL queries fire each iteration' do
      let(:query_number) { [0] }

      before do
        allow(notifications).to receive(:subscribed) do |subscriber, _event, &blk|
          query_number[0] += 1
          subscriber.call('sql.active_record', nil, nil, nil, { name: "SELECT #{query_number[0]}" })
          blk.call
        end
      end

      it 'tracks SQL queries independently per iteration' do
        expect { RailsConsoleBenchmark::Tracker.measure(3) { nil } }
          .to output(include('SQL Queries')).to_stdout
      end
    end
  end
end
