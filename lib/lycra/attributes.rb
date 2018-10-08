require 'lycra/attributes/collection'
require 'lycra/attributes/attribute'

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
        child.send :instance_variable_set,
                   :@_lycra_attributes,
                   Collection.new(child, self.attributes.map { |k,attr|
                     duped = attr.dup
                     duped.instance_variable_set(:@klass, child)
                     [k, duped]
                   }.to_h)
        child.send :delegate, :attributes, to: child
      end

      def types
        Lycra::Types
      end

      def attribute(name=nil, type=nil, *args, **opts, &block)
        opts = {cache: cache}.merge(opts)
        attr = Attribute.new(name, type, *args, **opts.merge({klass: self}), &block)
        attributes[attr.name] = attr
      end

      def attribute!(name=nil, type=nil, *args, **opts, &block)
        attribute(name, type, *args, **opts.merge({required: true}), &block)
      end

      def attributes
        @_lycra_attributes ||= Collection.new(self)
      end

      def subject_type(klass=nil)
        @_lycra_subject_type = klass if klass
        @_lycra_subject_type ||= (name.gsub(/(Decorator|Document|Serializer)\Z/, '').constantize rescue nil)
      end

      def subject_type=(klass)
        subject_type klass
      end

      def cache(cache=nil)
        @_lycra_cache = cache unless cache.nil?
        @_lycra_cache
      end

      def resolve!(subj, *args, **context)
        if subj.is_a?(subject_type)
          return new(subj).resolve!(*args, **context)
        elsif subj.is_a?(Enumerable) && subj.first.is_a?(subject_type)
          return subj.map { |s| resolve!(s, *args, **context) }
        end

        raise "Invalid subject: #{subj}"
      end

      def method_missing(meth, *args, &block)
        if subject_type && subject_type.respond_to?(meth)
          result = subject_type.send(meth, *args, &block)

          return result.try(:document) || new(result) if result.is_a?(subject_type)
          return result.map { |r| r.try(:document) || new(r) } if result.is_a?(Enumerable) && result.first.is_a?(subject_type)

          return result
        else
          super
        end
      end

      def respond_to_missing?(meth, priv=false)
        (subject_type && subject_type.respond_to?(meth, priv)) || super
      end

      def inspect
        "#{name}(subject: #{subject_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.nested? ? "[#{attr.type.type}]" : attr.type.type}"}.join(', ')})"
      end
    end

    module InstanceMethods
      delegate :subject_type, to: :class

      def initialize(subject)
        @subject = subject
      end

      def resolve!(*args, **options)
        raise Lycra::MissingSubjectError.new(self) if subject.nil?
        context = options.slice!(:only, :except)

        @resolved = attributes.map do |key,attr|
          next if (options.key?(:only) && ![options[:only]].flatten.include?(key)) ||
                  (options.key?(:except) && [options[:except]].flatten.include?(key))
          [ key, attr.dup.resolve!(self, args, context) ]
        end.compact.to_h
      end

      def resolved?
        !!@resolved
      end

      def reload
        @resolved = nil
        attributes.values.each(&:reload)
        subject.send(:reload) if subject.respond_to?(:reload)
        self
      end

      def method_missing(meth, *args, &block)
        return subject if meth == subject_type.to_s.underscore.to_sym
        return attributes[meth].resolve!(self, *args, &block) if attributes.key?(meth)
        return subject.send(meth, *args, &block) if subject && subject.respond_to?(meth)
        super
      end

      def respond_to_missing?(meth, priv=false)
        meth == subject_type.to_s.underscore.to_sym || attributes.key?(meth) || (subject && subject.respond_to?(meth, priv)) || super
      end

      def inspect
        if resolved?
          "#<#{self.class.name} subject: #{subject.class}, #{attributes.map { |key,attr| "#{key}: #{resolved[key].try(:to_json) || (attr.nested? ? "[#{attr.type.type}]" : attr.type.type)}"}.join(', ')}>"
        else
          "#<#{self.class.name} subject: #{subject.class}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.nested? ? "[#{attr.type.type}]" : attr.type.type}"}.join(', ')}>"
        end
      end
    end
  end
end
