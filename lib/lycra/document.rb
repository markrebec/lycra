require 'lycra/attribute'
require 'lycra/document/proxy'

module Lycra
  module Document
    def self.included(base)
      base.send :extend,  ClassMethods
      base.send :include, InstanceMethods
      # generic enough to build simple serializers or whatever
      base.send :include, Attributes
      # elasticsearch specific
      base.send :include, Proxy
      base.send :include, Indexing

      base.class_eval do
        # This does some work required to setup new instances of things
        # that won't conflict with the parent class
        def self.inherited(child)
          child.send :delegate, :document_type, :document_model, :index_name, to: child

          child.class_eval do
            class << self
              delegate :import, :search, to: :__lycra__
            end

            self.__lycra__.class_eval do
              include  ::Elasticsearch::Model::Importing::ClassMethods
              include  ::Elasticsearch::Model::Adapter.from_class(child).importing_mixin
            end
          end
        end
      end
    end

    module ClassMethods
      def find(*args, &block)
        new(document_model.find(*args, &block))
      end
    end

    module InstanceMethods
      def method_missing(meth, *args, &block)
        _lycra_subject.send(meth, *args, &block) if _lycra_subject && _lycra_subject.respond_to?(meth)
      end

      def respond_to?(meth, priv=false)
        (_lycra_subject && _lycra_subject.respond_to?(meth, priv)) || super
      end
    end

    module Attributes
      def self.included(base)
        base.send :attr_accessor, :_lycra_subject
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
        base.send :delegate, :attributes, to: base

        base.class_eval do
          attribute! :id, types.integer # TODO only for activerecord models

          # This clones parent attribues down to inheriting child classes
          def self.inherited(child)
            child.send :instance_variable_set, :@_lycra_attributes, self.attributes.try(:dup)
            child.send :delegate, :attributes, to: child
          end
        end
      end

      module ClassMethods
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

    # TODO move this all into the proxy to better emulate the elasticsearch-model stuff
    module Indexing
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
        base.send :delegate, :document_type, :document_model, :index_name, to: base
      end

      module ClassMethods
        def index_name(index=nil)
          @_lycra_index_name = index if index
          @_lycra_index_name ||= document_type.pluralize
        end

        def index_name=(index)
          index_name index
        end

        def document_type(type=nil)
          @_lycra_document_type = type if type
          @_lycra_document_type ||= name.demodulize.gsub(/Document\Z/, '').underscore
        end

        def document_type=(type)
          document_type type
        end

        def document_model(model=nil)
          @_lycra_document_model = model if model
          @_lycra_document_model ||= (name.gsub(/Document\Z/, '').constantize rescue nil)
        end

        def document_model=(model)
          document_model model
        end

        def mapping(mapping=nil)
          @_lycra_mapping = mapping if mapping
          { document_type.to_s.underscore.to_sym => (@_lycra_mapping || {}).merge({
              properties: attributes.map { |name, type| [name, type.mapping] }.to_h
          }) }
        end
        alias_method :mappings, :mapping

        def settings(settings=nil)
          @_lycra_settings = settings if settings
          @_lycra_settings || {}
        end

        def as_indexed_json(obj, options={})
          resolve!(obj).as_json(options)
        end
      end

      module InstanceMethods
        def as_indexed_json(options={})
          resolve!.as_json(options)
        end
      end
    end
  end
end
