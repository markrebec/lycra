module Lycra
  module Attributes
    class Collection
      include Enumerable

      attr_reader :attributes

      def initialize
        @attributes = {}
      end

      def each(&block)
        @attributes.each(&block)
      end

      def method_missing(meth, *args, &block)
        if @attributes.respond_to?(meth)
          @attributes.send(meth, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(meth, include_private=false)
        @attributes.respond_to?(meth, include_private) || super
      end
    end
  end
end
