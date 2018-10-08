module Lycra
  module Attributes
    class Collection
      include Enumerable

      attr_reader :attributes

      def initialize(klass, attributes={})
        @klass = klass
        @attributes = attributes
      end

      def dup(klass=nil)
        self.class.new(klass || @klass, attributes.map { |k,attr|
          duped = attr.dup
          duped.instance_variable_set(:@klass, klass || @klass)
          [k, duped]
        }.to_h)
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
