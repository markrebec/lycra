module Lycra
  module Search
    class Sort < Array
      alias_method :to_query, :to_a
      alias_method :to_q, :to_query
    end
  end
end
