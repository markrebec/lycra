require 'lycra/proxy'

module Lycra
  module Document
    def self.included(base)
      base.send :include, Attributes
      base.send :include, Proxy
    end
  end
end
