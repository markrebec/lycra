require 'lycra/attribute'

module Lycra
  module Attributes
    def self.included(base)
      base.send :attr_accessor, :_lycra_subject
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
      base.send :delegate, :attributes, to: base

      base.class_eval do
        attribute! :id, types.integer # TODO move to Lycra::Model::Document
      end
    end

    module ClassMethods
      def inherited(child)
        super if defined?(super)

        # This clones parent attribues down to inheriting child classes
        child.send :instance_variable_set, :@_lycra_attributes, self.attributes.try(:dup)
        child.send :delegate, :attributes, to: child
      end

      def types
        Lycra::Types
      end

      def attribute(name=nil, type=nil, *args, **opts, &block)
        attr = Attribute.new(name, type, *args, **opts, &block)
        attributes[attr.name] = attr
      end

      def attribute!(name=nil, type=nil, *args, **opts, &block)
        attribute(name, type, *args, **opts.merge({required: true}), &block)
      end

      def attributes
        @_lycra_attributes ||= {}
      end

      def resolve!(obj, *args, **context)
        new(obj).resolve!(*args, **context)
      end
    end

    module InstanceMethods
      def resolve!(*args, **context)
        raise Lycra::MissingSubjectError.new(self) if _lycra_subject.nil?
        attributes.map do |key,attr|
          [ key, attr.resolve!(_lycra_subject, args, context) ]
        end.to_h
      end
    end
  end
end
