# RailsConsoleBenchmark – Project Guidelines

## Purpose

`rails_console_benchmark` is a Ruby gem for profiling a block of code from the Rails (or plain Ruby) console. It measures:

- **Wall time** – via `Process.clock_gettime(Process::CLOCK_MONOTONIC)`, reported in milliseconds rounded to 3 decimal places.
- **SQL query count** – via `ActiveSupport::Notifications.subscribed` on `sql.active_record`. Skips `SCHEMA` and `CACHE` named queries. Only tracked when `ActiveSupport::Notifications` is defined (Rails is optional).
- **Memory allocation** – via `memory_profiler` (`MemoryProfiler.report`). Captures `total_allocated_memsize` and `total_retained_memsize`. Memory profiling is only run on the **first iteration** because it is expensive.

Results are displayed in a formatted terminal table using `terminal-table`.

## Architecture

Three classes under the `RailsConsoleBenchmark` module:

| File | Responsibility |
|------|---------------|
| `lib/rails_console_benchmark/tracker.rb` | Orchestrates measurement: iterates, times, tracks SQL, profiles memory. |
| `lib/rails_console_benchmark/formatter.rb` | Renders results as a `Terminal::Table`. Single-iteration → `Metric / Value`; multi-iteration → `Metric / Min / Max / Mean / Total`. |
| `lib/rails_console_benchmark/version.rb` | `VERSION` constant only. |

Primary public API: `RailsConsoleBenchmark::Tracker.measure(iterations = 1, &block)`.

## Key Conventions

- Every file starts with `# frozen_string_literal: true`.
- Rails/ActiveRecord is **optional**. Always guard with `defined?(ActiveSupport::Notifications)` – never `require 'active_record'` or `require 'rails'` directly.
- Use `Process.clock_gettime(Process::CLOCK_MONOTONIC)` for timing – never `Time.now` or `Time.current`.
- `MemoryProfiler.report` wraps the timed block; the wall-time measurement runs inside the profiler block.
- SQL subscriber is a `lambda` (not a proc) so `next` is used to skip unwanted events, not `return`.
- `Formatter` receives a single hash with keys `:wall_times_ms`, `:sql_queries`, `:allocated_memory`, `:retained_memory`.
- Memory bytes are formatted with `format_bytes` using 1024-based units (B / KB / MB / GB).

## Dependencies

| Gem | Version | Role |
|-----|---------|------|
| `memory_profiler` | `~> 1.0` | Memory allocation/retention profiling |
| `terminal-table` | `~> 3.0` | Console table rendering |

Rails (`activerecord`, `activesupport`) is an **optional runtime dependency** – code must function without it.

Required Ruby version: **>= 3.2.0**.

## Build and Test

```bash
bin/setup          # install dependencies
rake spec          # run the full test suite
bundle exec rake install  # install gem locally
```

Tests use **RSpec** with:
- `config.disable_monkey_patching!`
- `expect` syntax only (not `should`)
- Persistence file at `.rspec_status`

### Spec best practices

**File layout** – mirror `lib/` under `spec/`:
- `spec/rails_console_benchmark/tracker_spec.rb`
- `spec/rails_console_benchmark/formatter_spec.rb`

**Pinning wall time** – stub `Process.clock_gettime` to return deterministic values rather than relying on real elapsed time:
```ruby
allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0) # 1000 ms
```

**MemoryProfiler** – stub `MemoryProfiler.report` to avoid the cost of real memory profiling in unit tests. Yield the block and return a double with `total_allocated_memsize` / `total_retained_memsize`:
```ruby
memory_report = instance_double(MemoryProfiler::Results,
  total_allocated_memsize: 1024,
  total_retained_memsize: 512)
allow(MemoryProfiler).to receive(:report).and_yield.and_return(memory_report)
```

**Rails-optional paths** – use two explicit `context` blocks to cover both code paths in `Tracker`:
```ruby
context 'without ActiveSupport::Notifications (non-Rails)' do
  # sql_queries key should be nil in the result
end

context 'with ActiveSupport::Notifications (Rails)' do
  before { stub_const('ActiveSupport::Notifications', double(...)) }
  # sql_queries key should contain counts
end
```

**SQL subscriber** – when testing the Rails path, fire a fake `sql.active_record` notification and verify the count. Use `stub_const` to inject the constant rather than conditionally `require`-ing ActiveSupport.

**Formatter isolation** – call `Formatter.display` directly with a hand-crafted result hash; capture stdout with `expect { }.to output(...).to_stdout` to assert the rendered table content without involving `Tracker`.

**Descriptive examples** – prefer granular `it` blocks per assertion over one large example:
```ruby
it 'rounds wall time to 3 decimal places'
it 'reports N/A for sql_queries when ActiveSupport is absent'
it 'only runs memory profiling on the first iteration'
```

**No external I/O** – specs must not hit the database, filesystem, or network. Stub all external dependencies.

## Style

- Follow standard Ruby community style (RuboCop).
- Classes go under the `RailsConsoleBenchmark` module namespace.
- Private helper methods are preferred over inline complexity.
- Keep `Tracker` and `Formatter` responsibilities separate – `Tracker` must not format output, `Formatter` must not measure anything.

## After Making Changes

Always run RuboCop after editing any Ruby file and fix all offences before finishing:

```bash
bundle exec rubocop
```
