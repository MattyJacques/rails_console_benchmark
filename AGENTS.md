# AGENTS.md — RailsConsoleBenchmark

A Ruby gem for profiling code blocks in the Rails (or plain Ruby) console. Measures wall time, SQL query count, and memory allocation.

**API:** `RailsConsoleBenchmark::Tracker.measure(iterations = 1, &block)`  
**Ruby:** >= 3.2.0  
**Dependencies:** `memory_profiler` ~> 1.0, `terminal-table` ~> 3.0 (Rails optional)

---

## Build / Lint / Test Commands

```bash
bin/setup                           # Install dependencies
rake spec                           # Run full test suite
bundle exec rubocop                  # Run linter
rake                                # Run both tests and linting (default)
bundle exec rspec spec/path.rb       # Run single spec file
bundle exec rspec spec/path.rb:15    # Run spec by line number
bundle exec rspec -e "description"   # Run spec by description
bundle exec rspec --coverage         # Run with coverage
bundle exec rake install             # Install gem locally
```

---

## Code Style

- **Style:** Standard Ruby community style (RuboCop, Target Ruby 3.2)
- **Files:** Start every source file with `# frozen_string_literal: true`
- **Namespacing:** All classes under `RailsConsoleBenchmark` module
- **Naming:** Classes/Modules = `PascalCase`, Methods = `snake_case`, Constants = `SCREAMING_SNAKE_CASE`
- **Private methods:** Use `private` keyword, no underscore prefix
- **Imports:** Use `require_relative` for internal files; external gems at file top
- **Formatting:** Two-space indent, no trailing whitespace, use `format()` over interpolation

### File Organization
```
lib/rails_console_benchmark/     # Source code
spec/rails_console_benchmark/    # Mirror of lib/
sig/rails_console_benchmark.rbs  # RBS type signatures
```

---

## Architecture

### Responsibility Separation
- **`Tracker`** — measures, times, tracks SQL, profiles memory. Must NOT format output.
- **`Formatter`** — renders results as `Terminal::Table`. Must NOT measure anything.
- **Formatter input:** Hash with keys `:wall_times_ms`, `:sql_queries`, `:allocated_memory`, `:retained_memory`

### Rails-Optional Pattern
```ruby
@track_sql = defined?(ActiveSupport::Notifications)

def with_sql_tracking(&block)
  return [block.call, nil] unless @track_sql
  # ... Rails path
end
```

Never `require 'active_record'` or `require 'rails'` directly.

### Timing
- Use `Process.clock_gettime(Process::CLOCK_MONOTONIC)` — never `Time.now`
- Convert to ms: `(wall_time * 1000).round(3)`

### Memory Profiling
- `MemoryProfiler.report` wraps the timed block on **first iteration only**

### SQL Subscriber
Use a **lambda** (not proc) so `next` can skip events:
```ruby
subscriber = lambda { |*, payload|
  next if payload[:name]&.start_with?('SCHEMA', 'CACHE')
  sql_count += 1
}
```

---

## Testing

### Spec Layout
Mirror `lib/` under `spec/` (e.g., `tracker_spec.rb`, `formatter_spec.rb`)

### RSpec Config
```ruby
config.disable_monkey_patching!
config.expect_with :rspec { |c| c.syntax = :expect }
config.example_status_persistence_file_path = '.rspec_status'
```

### Common Stubs
```ruby
# Time: stub Process.clock_gettime for deterministic timing
allow(Process).to receive(:clock_gettime).and_return(0.0, 1.0) # 1000ms elapsed

# MemoryProfiler: avoid expensive real profiling
memory_report = instance_double(MemoryProfiler::Results,
  total_allocated_memsize: 1024, total_retained_memsize: 512)
allow(MemoryProfiler).to receive(:report).and_yield.and_return(memory_report)
```

### Rails-Optional Tests
```ruby
context 'without ActiveSupport::Notifications (non-Rails)' do
  it 'passes nil for sql_queries' # ...
end

context 'with ActiveSupport::Notifications (Rails)' do
  let(:notifications) { Module.new }
  before { stub_const('ActiveSupport::Notifications', notifications) }
  it 'counts SQL queries' # ...
end
```

### Stubbing SQL Events
```ruby
def stub_sql_events(*names)
  allow(notifications).to receive(:subscribed) do |subscriber, _event, &blk|
    names.each { |name| subscriber.call('sql.active_record', nil, nil, nil, { name: name }) }
    blk.call
  end
end
```

### Formatter Testing
```ruby
result = { wall_times_ms: [1.0], sql_queries: nil, allocated_memory: 1024, retained_memory: 512 }
expect { described_class.display(result) }.to output(include('2.00 KB')).to_stdout
```

### Guidelines
- Granular `it` blocks per assertion
- No external I/O — stub all database/filesystem/network calls
- Use `described_class` instead of hardcoded class names
- Descriptive names: `it 'rounds wall time to 3 decimal places'`

---

## After Changes

Always run: `bundle exec rubocop && bundle exec rspec`

### Update CHANGELOG.md
Under `[Unreleased]` for any user-facing change (Added/Changed/Deprecated/Removed/Fixed/Security)

### Update README.md
If change affects public API, usage examples, or supported versions

### Update RBS
If change affects public method signatures, module/class definitions, or result hash shape
