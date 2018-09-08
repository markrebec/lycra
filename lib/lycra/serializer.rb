module Lycra
  module Serializer
    def self.included(base)
      base.send :include, Attributes
      base.send :alias_method, :serialize!, :resolve!

      base.class_eval do
        class << self
          alias_method :serialize!, :resolve!
        end
      end
    end
  end
end
