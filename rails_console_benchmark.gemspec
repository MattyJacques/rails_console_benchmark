# frozen_string_literal: true

require_relative 'lib/rails_console_benchmark/version'

Gem::Specification.new do |spec|
  spec.name = 'rails_console_benchmark'
  spec.version = RailsConsoleBenchmark::VERSION
  spec.authors = ['Matthew Jacques']
  spec.email = ['matty.jacques@proton.me']

  spec.summary = 'Profile Ruby/Rails console block execution: wall time, SQL query count, and memory usage.'
  spec.description = 'A gem that measures block execution time, database query counts (when ActiveRecord is present), and memory allocation, displaying results in a formatted terminal table. Works in plain Ruby and Rails projects alike.'
  spec.homepage = 'https://github.com/MattyJacques/rails_console_benchmark'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/MattyJacques/rails_console_benchmark'
  spec.metadata['changelog_uri'] = 'https://github.com/MattyJacques/rails_console_benchmark/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'memory_profiler', '~> 1.0'
  spec.add_dependency 'terminal-table', '~> 3.0'
  # Rails (railties, activerecord) is optional — loaded automatically when present

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
