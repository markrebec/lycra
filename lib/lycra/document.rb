require 'lycra/document/base'

module Lycra
  module Document
    def self.included(base)
      base.send :include, Attributes
    end

    module Attributes
      def self.included(base)
        base.send :attr_accessor, :_lycra_subject
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        def attribute(name, type=nil, *args, **opts, &block)
          attributes[name] = Attribute.new(name, type, *args, **opts, &block)
        end

        def attributes
          @_lycra_attributes ||= {}
        end

        def resolve!(obj, *args, **context)
          new(obj).resolve!(*args, **context)
        end
      end

      module InstanceMethods
        def attributes
          self.class.attributes
        end

        def resolve!(*args, **context)
          raise Lycra::MissingSubjectError, _lycra_nil_subject_message if _lycra_subject.nil?
          attributes.map do |key,attr|
            [ key, attr.resolve!(_lycra_subject, args, context) ]
          end.to_h
        end
      end
    end

    def _lycra_nil_subject_message
      message = "This document was initialized with a nil subject. "
      if is_a?(Lycra::Document::Base)
        message += "It looks like you're inheriting from the Lycra::Document::Base class, so make sure to pass an object when calling `#{self.class.name}.new`, and if you're overriding the initializer be sure to call `super` with the appropriate argument."
      else
        message += "It looks like you're using the Lycra::Document mixin, make sure you set @_lycra_subject before resolving (i.e. in your class initializer)."
      end
      message
    end
  end
end
