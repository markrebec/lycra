require 'logger'
require 'canfig'
require 'elasticsearch/model'
require 'lycra/engine' if defined?(Rails)

module Lycra
  include Canfig::Module

  configure do |config|
    config.elasticsearch_host = ENV['ELASTICSEARCH_HOST'] || 'localhost'    # elasticsearch host to use when connecting, defaults to ENV var if set or falls back to localhost
    config.elasticsearch_port = ENV['ELASTICSEARCH_PORT'] || 9200           # elasticsearch port to use when connecting, defaults to ENV var if set or falls back to 9200
    config.elasticsearch_url  = ENV['ELASTICSEARCH_URL']                    # elasticsearch URL to use when connecting (i.e. 'https://localhost:9200'), this will override host/port if set
    config.logger             = nil                                         # defaults to STDOUT but will use Rails.logger in a rails environment (via Lycra::Engine)

    def elasticsearch_url
      @state[:elasticsearch_url] || "#{self.elasticsearch_host}:#{self.elasticsearch_port}"
    end

    def logger
      @logger ||= (@state[:logger] || Logger.new(STDOUT))
    end
  end

end
