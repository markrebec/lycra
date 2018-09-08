require 'lycra/proxy/document'

module Lycra
  module Document
    def self.included(base)
      base.send :include, Attributes
      base.send :include, Proxy::Document
    end
  end
end
