module Lycra
  module Search
    class Aggregations < Array
      def to_query
        return {} if empty?

        # can probably inject here or be a bit more elegant?
        aggregations = {}
        each { |agg| aggregations.merge!(agg) }
        aggregations
      end
      alias_method :to_q, :to_query
    end
  end
end
