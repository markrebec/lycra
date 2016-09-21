module Lycra
  module Search
    class Query < Array
      def to_query
        return {} if empty? && filters.empty?

        query_matcher = {}
        query_matcher.merge!(must_matchers) unless must_matchers.empty?
        query_matcher.merge!(should_matchers) unless should_matchers.empty?
        query_filters = {filter: filters.to_query}
        {
          bool: query_matcher.merge(query_filters)
        }
      end
      alias_method :to_q, :to_query

      def filters
        @filters ||= Lycra::Search::Filters.new
      end

      def filter(fltr=nil)
        if fltr.present?
          filters << fltr
        end

        self
      end

      def refilter(fltr)
        @filters = Lycra::Search::Filters.new
        filter fltr
      end

      protected

      def must_matchers
        queries = select { |q| q.key?(:must) || !q.key?(:should) }
        return {} if queries.empty?

        matchers = {must: []}
        queries.each do |query|
          if query.key?(:must)
            matchers[:must].concat(query[:must])
          else
            matchers[:must] << query
          end
        end
        matchers
      end

      def should_matchers
        queries = select { |q| q.key?(:should) }
        return {} if queries.empty?

        matchers = {should: []}
        queries.each do |query|
          matchers[:should].concat(query[:should])
        end
        matchers
      end
    end
  end
end
