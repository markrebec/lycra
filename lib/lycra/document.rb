require 'lycra/proxy/document'

module Lycra
  module Document
    # TODO copy this to a Lycra::Serializer and strip it down
    def self.included(base)
      base.send :extend,  ClassMethods
      base.send :include, InstanceMethods

      # generic enough to build simple serializers or whatever
      base.send :include, Attributes

      # elasticsearch specific
      base.send :include, Proxy::Document
    end

    module ClassMethods
      # TODO only needed by Lycra::Model::Document
      def find(*args, &block)
        new(subject_type.find(*args, &block))
      end
    end

    module InstanceMethods
      def method_missing(meth, *args, &block)
        return subject.send(meth, *args, &block) if subject && subject.respond_to?(meth)
        super
      end

      def respond_to?(meth, priv=false)
        (subject && subject.respond_to?(meth, priv)) || super
      end
    end
  end
end
