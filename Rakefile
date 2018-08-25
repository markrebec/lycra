require 'rspec/core/rake_task'

load './lib/tasks/db.rake'
load './lib/tasks/gem.rake'

task :environment do
  # noop
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -r rubygems -I lib -r ./console"
end

desc "Run the specs"
RSpec::Core::RakeTask.new do |r|
  r.verbose = false
end

task :default => ['db:test:prepare', :spec]
