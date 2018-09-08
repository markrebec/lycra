$:.push File.expand_path("../lib", __FILE__)
require "lycra/version"

Gem::Specification.new do |s|
  s.name        = "lycra"
  s.version     = Lycra::Version::VERSION
  s.summary     = "Better elasticsearch documents for ruby"
  s.description = "Better elasticsearch documents for ruby"
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.homepage    = "http://github.com/markrebec/lycra"

  s.files       = Dir["lib/lycra.rb", "lib/lycra/**/*"]
  s.test_files  = Dir["spec/**/*"]

  s.add_dependency "canfig"
  s.add_dependency "elasticsearch-persistence", "~> 5.0"
  s.add_dependency "elasticsearch-model", "~> 5.0"
  s.add_dependency "elasticsearch-rails", "~>5.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "activerecord", "~> 5.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "factory_bot"
  s.add_development_dependency "faker"
  s.add_development_dependency "byebug"
  s.add_development_dependency "awesome_print"
end
