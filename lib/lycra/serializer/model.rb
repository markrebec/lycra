module Lycra
  module Serializer
    module Model
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def serializer(klass=nil)
          @_lycra_serializer = klass if klass
          @_lycra_serializer || ("#{name}Serializer".constantize rescue nil)
        end

        def serializer=(klass)
          serializer klass
        end
      end

      module InstanceMethods
        delegate :serialize!, to: :serializer

        def reload
          @serializer = nil
          super
        end

        def serializer
          @serializer ||= self.class.serializer.new(self)
        end
      end
    end
  end
end
