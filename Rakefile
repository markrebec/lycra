require 'rspec/core/rake_task'

task :environment do
  # noop
end

desc 'Run the specs'
RSpec::Core::RakeTask.new do |r|
  r.verbose = false
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -r rubygems -I lib -r lycra -r byebug"
end

task :build do
  puts `gem build lycra.gemspec`
end

task :push do
  require 'lycra/version'
  puts `gem push lycra-#{Lycra::Version::VERSION}.gem`
end

task release: [:build, :push] do
  puts `rm -f lycra*.gem`
end

task :default => :spec
