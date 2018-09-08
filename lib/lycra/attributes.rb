require 'lycra/attribute'

module Lycra
  module Attributes
    def self.included(base)
      base.send :attr_reader, :resolved
      base.send :attr_accessor, :subject
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
      base.send :delegate, :attributes, to: base

      base.class_eval do
        # TODO only for activerecord models??
        attribute! :id, types.integer
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

      def subject_type(klass=nil)
        @_lycra_subject_type = klass if klass
        @_lycra_subject_type ||= (name.gsub(/(Document|Serializer)\Z/, '').constantize rescue nil)
      end

      def subject_type=(klass)
        subject_type klass
      end

      def resolve!(obj, *args, **context)
        new(obj).resolve!(*args, **context)
      end

      def method_missing(meth, *args, &block)
        return subject_type.send(meth, *args, &block) if subject_type && subject_type.respond_to?(meth)
        super
      end

      def respond_to?(meth, priv=false)
        (subject_type && subject_type.respond_to?(meth, priv)) || super
      end

      def inspect
        "#{name}(subject: #{subject_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')})"
      end
    end

    module InstanceMethods
      delegate :subject_type, to: :class

      def resolve!(*args, **context)
        raise Lycra::MissingSubjectError.new(self) if subject.nil?
        @resolved = attributes.map do |key,attr|
          [ key, attr.resolve!(subject, args, context) ]
        end.to_h
      end

      def reload
        @resolved = nil
        self
      end

      def method_missing(meth, *args, &block)
        return subject.send(meth, *args, &block) if subject && subject.respond_to?(meth)
        super
      end

      def respond_to?(meth, priv=false)
        (subject && subject.respond_to?(meth, priv)) || super
      end

      def inspect
        if @resolved
          "#<#{self.class.name} subject: #{subject.class}, #{@resolved.map { |key,attr| "#{key}: #{attr.to_json}"}.join(', ')}>"
        else
          "#<#{self.class.name} subject: #{subject.class}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')}>"
        end
      end
    end
  end
end
