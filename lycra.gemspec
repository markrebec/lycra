$:.push File.expand_path("../lib", __FILE__)
require "lycra/version"

Gem::Specification.new do |s|
  s.name        = "lycra"
  s.version     = Lycra::Version::VERSION
  s.summary     = "Business intelligence based on elasticsearch queries"
  s.description = "Open source business intelligence based on elasticsearch queries, inspired by https://github.com/ankane/blazer"
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.homepage    = "http://github.com/markrebec/lycra"

  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir["spec/**/*"]

  s.add_dependency "canfig"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  #s.add_development_dependency "vcr"
  #s.add_development_dependency "webmock"
end
