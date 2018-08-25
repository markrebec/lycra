namespace :gem do
  desc "Build this gem to prepare for release or testing"
  task :build do
    puts `gem build lycra.gemspec`
  end

  desc "Push the current built version of the gem up to rubygems"
  task :push do
    require 'lycra/version'
    puts `gem push lycra-#{Lycra::Version::VERSION}.gem`
  end

  desc "Build the current version of the gem and push it to rubygems"
  task release: [:build, :push] do
    puts `rm -f lycra*.gem`
  end
end
