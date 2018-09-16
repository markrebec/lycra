module Lycra
  module Decorator
    module Model
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def decorator(klass=nil)
          @_lycra_decorator = klass if klass
          @_lycra_decorator || ("#{name}Decorator".constantize rescue nil)
        end

        def decorator=(klass)
          decorator klass
        end
      end

      module InstanceMethods
        def reload
          @decorator = nil
          super
        end

        def decorator(decorator_class=nil)
          return decorator_class.new(self) if decorator_class
          @decorator ||= self.class.decorator.new(self)
        end
      end
    end
  end
end
