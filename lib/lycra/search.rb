require 'lycra/search/aggregations'
require 'lycra/search/filters'
require 'lycra/search/query'
require 'lycra/search/sort'
require 'lycra/search/enumerable'
require 'lycra/search/pagination'
require 'lycra/search/scoping'

module Lycra
  module Search
    def self.included(base)
      base.send :include, Lycra::Search::Enumerable
      base.send :include, Lycra::Search::Pagination
      base.send :include, Lycra::Search::Scoping
      base.send :extend, ClassMethods
      base.send :attr_reader, :term
    end

    def initialize(term=nil, query: nil, filter: nil, post_filter: nil, sort: nil, models: nil, fields: nil, aggregations: nil, &block)
      @term = term
      @models = models
      @fields = fields
      self.query(block_given? ? instance_eval(&block) : query)
      self.filter(filter)
      self.post_filter(post_filter)
      self.sort(sort)
      self.aggregate(aggregations)
    end

    def response
      @response ||= search
    end

    def response!
      @response = search
    end

    def document_types
      document_types ||= response.search.definition[:type]
    end

    def entry_name
      if document_types.count == 1
        document_types.first
      elsif document_types.count > 1
        return document_types.map(&:pluralize).to_sentence
      else
        'result'
      end
    end

    def search(qry=nil, &block)
      if block_given?
        Elasticsearch::Model.search(instance_eval(&block), models)
      else
        Elasticsearch::Model.search((qry || to_query), models)
      end
    end

    def query(qry=nil)
      if !qry.nil?
        @query = Lycra::Search::Query[qry]
        self
      else
        @query ||= Lycra::Search::Query[send("#{query_method}_query")]
      end
    end

    def to_query_hash
      {
        query: query.to_query,
        filter: filters.to_query,
        sort: sorter.to_query,
        post_filter: post_filters.to_query,
        aggregations: aggregations.to_query
      }
    end
    alias_method :to_query, :to_query_hash
    alias_method :to_q, :to_query_hash

    def match_all_query
      {match_all: {}}
    end

    def multi_match_query
      return if term.nil?

      {
        multi_match: {
          query: term,
          type: :best_fields,
          fields: fields,
          tie_breaker: 0.5,
          operator: 'and'
        }
      }
    end

    def match_phrase_prefix_query
      return if term.nil?

      field_queries = fields.map do |field|
        {match_phrase_prefix: {field.to_s.gsub(/\^\d\Z/, '').to_sym => term}}
      end

      {or: field_queries}
    end

    def query_method(meth=false)
      if meth == false
        @query_method ||= :match_all
      else
        @query = nil
        @query_method = meth
        self
      end
    end

    def models(mdls=false)
      if mdls != false
        @models = mdls.is_a?(Array) ? mdls : [mdls]
      else
        @models ||= self.class.models
      end
    end

    def fields(flds=false)
      if flds != false
        @fields = flds.is_a?(Array) ? flds : [flds]
      else
        @fields ||= self.class.fields
      end
    end

    module ClassMethods
      def inherited(base)
        # Make sure we inherit the parent's class-level instance variables whenever we inherit from the class.
        base.send :instance_variable_set, :@models,    models.try(:dup)
        base.send :instance_variable_set, :@fields, fields.try(:dup)
      end

      def search(term=nil, query: nil, filter: nil, post_filter: nil, sort: nil, models: nil, fields: nil, aggregations: nil, &block)
        new(term, query: query, filter: filter, post_filter: post_filter, sort: sort, models: models, fields: fields, aggregations: aggregations, &block)
      end

      def singleton
        @singleton ||= search
      end

      def method_missing(meth, *args, &block)
        return search.send(meth, *args, &block) if singleton.respond_to?(meth)
        super
      end

      def respond_to_missing?(meth, include_private=false)
        singleton.respond_to?(meth, include_private) || super
      end

      def fields(*fields)
        @fields = fields unless fields.empty?
        @fields ||= []
      end

      def models(*models)
        @models = models unless models.empty?
        @models ||= []
      end
    end
  end
end
