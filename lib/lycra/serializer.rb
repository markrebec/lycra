module Lycra
  module Serializer
    def self.included(base)
      base.send :include, Attributes
      base.send :extend,  Inheritance
      base.send :alias_method, :serialize!, :resolve!

      base.class_eval do
        class << self
          alias_method :serialize!, :resolve!
        end
      end
    end

    def as_json(options={})
      serialize!(subject).as_json(options)
    end
  end
end
