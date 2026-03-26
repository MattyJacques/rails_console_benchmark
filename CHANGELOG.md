## [Unreleased]

## [0.0.1] - 2026-03-26

### Added

- `Tracker.measure` for profiling a block of Ruby/Rails code.
- Wall time measurement via `Process.clock_gettime(Process::CLOCK_MONOTONIC)`, reported in milliseconds (3 decimal places).
- SQL query count tracking via `ActiveSupport::Notifications` (Rails-optional; skips `SCHEMA` and `CACHE` queries).
- Memory allocation and retention profiling via `memory_profiler` (first iteration only).
- Results displayed as a formatted terminal table via `terminal-table`.
- Multi-iteration support: pass an integer to `Tracker.measure(n)` to run the block N times and display min/max/mean/total statistics.
- Full RSpec test suite covering `Tracker` and `Formatter`, including Rails-optional and non-Rails code paths.
- SimpleCov test coverage reporting.
- RuboCop integration (with `rubocop-rake` and `rubocop-rspec`) for code style and quality enforcement.
- Full RBS type signatures for `Tracker` and `Formatter` in `sig/rails_console_benchmark.rbs`.
- `Formatter` displays `N/A` for SQL Queries when `ActiveSupport::Notifications` is not available.
