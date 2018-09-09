module Lycra
  module Decorator
    def self.included(base)
      base.send :include, Attributes
    end

    def as_json(options={})
      resolve!(subject).as_json(options)
    end
  end
end
