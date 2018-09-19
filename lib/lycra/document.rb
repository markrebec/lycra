require 'lycra/document/proxy'

module Lycra
  module Document
    def self.included(base)
      base.send :include, Attributes
      base.send :extend,  Inheritance
      base.send :include, Proxy
    end
  end
end
