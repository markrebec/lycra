module Lycra
  class Query
    attr_reader :model, :term, :query, :filters, :facets

    def execute
      # TODO
    end

    def index
      model.index_name
    end

    def as_json(opts={})
      { model: model.name,
        term: term,
        query: query,
        filters: filters,
        facets: facets }
    end
    alias_method :to_hash, :as_json

    def to_json(opts={})
      as_json(opts).to_s
    end

    protected

    def initialize(model, term: nil, query: {}, filters: {}, facets: {}, &block)
      @model = model
      @term = term
      @query = query
      @filters = filters
      @facets = facets
    end
  end
end
