module Lycra
  module Serializer
    def self.included(base)
      base.send :include, Attributes
    end
  end
end
