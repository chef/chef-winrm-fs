# frozen_string_literal: true

require "rubygems" unless defined?(Gem)
require "bundler/setup"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# Change to the directory of this file.
Dir.chdir(File.expand_path(__dir__))

# For gem creation and bundling
require "bundler/gem_tasks"

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = "spec/unit/*_spec.rb"
  task.rspec_opts = ["--color", "-f documentation"]
end

desc "Check Linting and code style."
task :style do
  require "rubocop/rake_task"
  require "cookstyle/chefstyle"

  if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
    # Windows-specific command, rubocop erroneously reports the CRLF in each file which is removed when your PR is uploaeded to GitHub.
    # This is a workaround to ignore the CRLF from the files before running cookstyle.
    sh "cookstyle --chefstyle -c .rubocop.yml --except Layout/EndOfLine"
  else
    sh "cookstyle --chefstyle -c .rubocop.yml"
  end
rescue LoadError
  puts "Rubocop or Cookstyle gems are not installed. bundle install first to make sure all dependencies are installed."
end

# Run the integration test suite
RSpec::Core::RakeTask.new(:integration) do |task|
  task.pattern = "spec/integration/*_spec.rb"
  task.rspec_opts = ["--color", "-f documentation"]
end

RuboCop::RakeTask.new

task default: %i{spec style}

task all: %i{default integration}
