# RailsConsoleBenchmark

A Ruby gem for profiling a block of code from the Rails (or plain Ruby) console. It measures wall time, SQL query count, and memory allocation, then displays the results in a formatted terminal table.

## Features

- **Wall time** — measured via `Process.clock_gettime(Process::CLOCK_MONOTONIC)`, reported in milliseconds (3 decimal places).
- **SQL query count** — tracked via `ActiveSupport::Notifications` when ActiveRecord is present. `SCHEMA` and `CACHE` queries are excluded.
- **Memory allocation** — total allocated and retained memory reported via `memory_profiler`. Memory profiling runs on the first iteration only.
- **Multi-iteration support** — run the block N times and get min/max/mean/total statistics.
- **Rails-optional** — works in plain Ruby projects with no ActiveRecord dependency.
- **Rails console auto-integration** — a Railtie makes `RailsConsoleBenchmark` available automatically in `rails console` when bundled in a Rails app.

## Installation

Add to your application's Gemfile:

```bash
bundle add rails_console_benchmark
```

Or install directly:

```bash
gem install rails_console_benchmark
```

## Usage

### Single run

```ruby
RailsConsoleBenchmark::Tracker.measure do
  MyModel.where(active: true).to_a
end
```

Example output:

```
+------------------+------------+
| Metric           | Value      |
+------------------+------------+
| Wall Time (ms)   | 42.371     |
| SQL Queries      | 1          |
| Allocated Memory | 512.00 KB  |
| Retained Memory  | 4.00 KB    |
+------------------+------------+
```

### Multiple iterations

```ruby
RailsConsoleBenchmark::Tracker.measure(10) do
  MyModel.where(active: true).to_a
end
```

Example output:

```
+------------------+--------+--------+---------+---------+
| Metric           | Min    | Max    | Mean    | Total   |
+------------------+--------+--------+---------+---------+
| Wall Time (ms)   | 38.112 | 56.903 | 44.210  | 442.100 |
| SQL Queries      | 1      | 1      | 1.0     | 10      |
| Allocated Memory | 512.00 KB | 512.00 KB | 512.00 KB | 512.00 KB |
| Retained Memory  | 4.00 KB   | 4.00 KB   | 4.00 KB   | 4.00 KB   |
+------------------+--------+--------+---------+---------+
```

> Memory figures are from the first iteration only, so min/max/mean/total all show the same value.

### Without Rails / ActiveRecord

When `ActiveSupport::Notifications` is not defined, the SQL Queries row displays `N/A`.

### Rails console auto-integration

When the gem is added to a Rails app's Gemfile, a Railtie automatically registers with Rails so `RailsConsoleBenchmark` is available in `rails console` without a manual `require`:

```ruby
# No require needed — just use it:
RailsConsoleBenchmark::Tracker.measure { MyModel.all.to_a }
```

## Requirements

- Ruby >= 3.2.0
- [`memory_profiler`](https://github.com/SamSaffron/memory_profiler) `~> 1.0`
- [`terminal-table`](https://github.com/tj/terminal-table) `~> 3.0`
- Rails / ActiveRecord is **optional**

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake spec` to run the test suite. You can also run `bin/console` for an interactive prompt.

To install the gem locally:

```bash
bundle exec rake install
```

To release a new version, update `VERSION` in `version.rb` and run:

```bash
bundle exec rake release
```

This creates a git tag, pushes commits and the tag, and publishes the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MattyJacques/rails_console_benchmark. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/MattyJacques/rails_console_benchmark/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailsConsoleBenchmark project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/MattyJacques/rails_console_benchmark/blob/main/CODE_OF_CONDUCT.md).
