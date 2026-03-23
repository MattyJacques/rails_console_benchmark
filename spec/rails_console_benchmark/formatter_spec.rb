# frozen_string_literal: true

RSpec.describe RailsConsoleBenchmark::Formatter do
  describe '.display' do
    context 'with a single iteration' do
      let(:result) do
        {
          wall_times_ms: [123.456],
          sql_queries: [5],
          allocated_memory: 2048,
          retained_memory: 1024
        }
      end

      it 'prints a table with Metric and Value headings' do
        expect { described_class.display(result) }.to output(include('Metric', 'Value')).to_stdout
      end

      it 'does not include multi-iteration headings' do
        expect { described_class.display(result) }.not_to output(include('Min', 'Max', 'Mean', 'Total')).to_stdout
      end

      it 'includes wall time' do
        expect { described_class.display(result) }.to output(include('123.456')).to_stdout
      end

      it 'includes the SQL query count' do
        expect { described_class.display(result) }.to output(include('SQL Queries', '5')).to_stdout
      end

      it 'includes formatted allocated memory' do
        expect { described_class.display(result) }.to output(include('2.00 KB')).to_stdout
      end

      it 'includes formatted retained memory' do
        expect { described_class.display(result) }.to output(include('1.00 KB')).to_stdout
      end
    end

    context 'with multiple iterations' do
      let(:result) do
        {
          wall_times_ms: [100.0, 200.0, 300.0],
          sql_queries: [3, 5, 4],
          allocated_memory: 1_048_576,
          retained_memory: 0
        }
      end

      it 'prints a table with Metric, Min, Max, Mean, Total headings' do
        expect { described_class.display(result) }
          .to output(include('Metric', 'Min', 'Max', 'Mean', 'Total')).to_stdout
      end

      it 'does not include single-iteration Value heading' do
        expect { described_class.display(result) }.not_to output(match(/\|\s+Value\s+\|/)).to_stdout
      end

      it 'includes wall time min' do
        expect { described_class.display(result) }.to output(include('100.0')).to_stdout
      end

      it 'includes wall time max' do
        expect { described_class.display(result) }.to output(include('300.0')).to_stdout
      end

      it 'includes wall time mean' do
        expect { described_class.display(result) }.to output(include('200.0')).to_stdout
      end

      it 'includes wall time total' do
        expect { described_class.display(result) }.to output(include('600.0')).to_stdout
      end

      it 'includes SQL min' do
        expect { described_class.display(result) }.to output(include('SQL Queries')).to_stdout
      end

      it 'includes SQL total' do
        expect { described_class.display(result) }.to output(include('12')).to_stdout
      end

      it 'includes SQL mean rounded to 3 decimal places' do
        expect { described_class.display(result) }.to output(include('4.0')).to_stdout
      end

      it 'repeats memory value across all columns' do
        expect { described_class.display(result) }
          .to output(include('1.00 MB')).to_stdout
      end

      it 'shows 0 B for retained memory when zero' do
        expect { described_class.display(result) }.to output(include('0 B')).to_stdout
      end
    end

    context 'without Rails (sql_queries is nil)' do
      it 'shows N/A for SQL queries in a single iteration result' do
        result = { wall_times_ms: [1.0], sql_queries: nil, allocated_memory: 1024, retained_memory: 512 }
        expect { described_class.display(result) }.to output(include('N/A')).to_stdout
      end

      it 'shows N/A for all SQL columns in a multi-iteration result' do
        result = { wall_times_ms: [1.0, 2.0], sql_queries: nil, allocated_memory: 1024, retained_memory: 512 }
        expect { described_class.display(result) }.to output(include('N/A')).to_stdout
      end
    end

    context 'with byte formatting' do
      def single_result(allocated:, retained:)
        { wall_times_ms: [1.0], sql_queries: nil, allocated_memory: allocated, retained_memory: retained }
      end

      it 'formats zero bytes as "0 B"' do
        expect { described_class.display(single_result(allocated: 0, retained: 0)) }
          .to output(include('0 B')).to_stdout
      end

      it 'formats bytes below 1 KB' do
        expect { described_class.display(single_result(allocated: 512, retained: 512)) }
          .to output(include('512.00 B')).to_stdout
      end

      it 'formats bytes as KB' do
        expect { described_class.display(single_result(allocated: 1024, retained: 1024)) }
          .to output(include('1.00 KB')).to_stdout
      end

      it 'formats bytes as MB' do
        expect { described_class.display(single_result(allocated: 1024 * 1024, retained: 1024 * 1024)) }
          .to output(include('1.00 MB')).to_stdout
      end

      it 'formats bytes as GB' do
        expect { described_class.display(single_result(allocated: 1024**3, retained: 1024**3)) }
          .to output(include('1.00 GB')).to_stdout
      end
    end
  end
end
