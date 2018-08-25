require 'logger'
require 'canfig'
require 'elasticsearch/persistence'
require 'elasticsearch/model'
#require 'lycra/monkeypatches' # TODO still need this?
require 'lycra/errors'
require 'lycra/types'
require 'lycra/attribute'
require 'lycra/document'
require 'lycra/model'
require 'lycra/search'
require 'lycra/engine' if defined?(Rails)

module Lycra
  include Canfig::Module

  configure do |config|
    config.elasticsearch_host = ENV['ELASTICSEARCH_HOST'] || 'localhost'    # elasticsearch host to use when connecting, defaults to ENV var if set or falls back to localhost
    config.elasticsearch_port = ENV['ELASTICSEARCH_PORT'] || 9200           # elasticsearch port to use when connecting, defaults to ENV var if set or falls back to 9200
    config.elasticsearch_url  = ENV['ELASTICSEARCH_URL']                    # elasticsearch URL to use when connecting (i.e. 'https://localhost:9200'), this will override host/port if set
    config.page_size          = 50                                          # default number of results to return per-page when searching an index
    config.index_prefix       = nil                                         # a prefix to use for index names (i.e. 'my-app' prefix and 'people' index becomes 'my-app-people')
    config.log                = false                                       # whether or not the elasticsearch client should perform standard logging
    config.logger             = nil                                         # logger use for standard elasticsearch logging, defaults to STDOUT but will use Rails.logger in a rails environment (via Lycra::Engine)
    config.trace              = false                                       # whether or not the elasticsearch client should log request/response traces
    config.tracer             = nil                                         # logger used when tracing request/response data

    def elasticsearch_url
      @state[:elasticsearch_url] || "#{self.elasticsearch_host}:#{self.elasticsearch_port}"
    end

    def logger
      @logger ||= (@state[:logger] || Logger.new(STDOUT))
    end
  end

  def self.client
    @client ||= Elasticsearch::Client.new(
      host: configuration.elasticsearch_url,
      log: configuration.log,
      logger: configuration.logger,
      trace: configuration.trace,
      tracer: configuration.tracer
    )
  end
end
