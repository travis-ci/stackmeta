begin
  require 'rubocop/rake_task'
  require 'rspec/core/rake_task'
rescue LoadError => e
  warn e
end

RuboCop::RakeTask.new if defined?(RuboCop)
RSpec::Core::RakeTask.new if defined?(RSpec)

task default: %i[rubocop spec]
