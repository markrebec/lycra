module Lycra
  module Search
    class Filters < Array
      def to_query
        return {} if empty?

        filters = {}
        filters.merge!(must_filters) unless must_filters.empty?
        filters.merge!(must_not_filters) unless must_not_filters.empty?
        {bool: filters}
      end
      alias_method :to_q, :to_query

      protected

      def must_filters
        queries = select { |q| q.key?(:must) || !q.key?(:must_not) }
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

      def must_not_filters
        queries = select { |q| q.key?(:must_not) }
        return {} if queries.empty?

        matchers = {must_not: []}
        queries.each do |query|
          matchers[:must_not].concat(query[:must_not])
        end
        matchers
      end
    end
  end
end
