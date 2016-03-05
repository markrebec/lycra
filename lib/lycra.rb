require 'canfig'
require 'lycra/engine'

module Lycra
  include Canfig::Module

  configure do |config|
    config.elastic_host   = nil           # the elasticsearch host to use
    config.logger         = nil           # defaults to STDOUT but will use Rails.logger in a rails environment via Lycra::Engine
  end

  def self.logger
    configuration.logger || Logger.new(STDOUT)
  end
end
