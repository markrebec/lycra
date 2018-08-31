require 'lycra/document/proxy'

module Lycra
  module Document
    # TODO copy this to a Lycra::Serializer and strip it down
    def self.included(base)
      base.send :extend,  ClassMethods
      base.send :include, InstanceMethods

      # generic enough to build simple serializers or whatever
      base.send :include, Attributes

      # elasticsearch specific
      base.send :include, Proxy
      base.send :include, Indexing
    end

    module ClassMethods
      # TODO only needed by Lycra::Model::Document
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

    # TODO move this all into the proxy to better emulate the elasticsearch-model stuff
    module Indexing
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
        # TODO document_model is only needed by Lycra::Model::Document
        base.send :delegate, :document_type, :document_model, :index_name, to: base
      end

      module ClassMethods
        # This does some work required to setup new instances of things
        # that won't conflict with the parent class
        def inherited(child)
          super if defined?(super)

          # TODO document_model is only needed by Lycra::Model::Document
          child.send :delegate, :document_type, :document_model, :index_name, to: child

          child.class_eval do
            self.__lycra__.class_eval do
              include  ::Elasticsearch::Model::Importing::ClassMethods
              include  ::Elasticsearch::Model::Adapter.from_class(child).importing_mixin
            end

            class << self
              delegate :import, :search, to: :__lycra__
            end
          end
        end

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

        def inspect
          "#{name}(index: #{index_name}, document: #{document_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')})"
        end
      end

      module InstanceMethods
        def as_indexed_json(options={})
          resolve!.as_json(options)
        end

        def _indexed
          @indexed ||= self.class.search({query: {terms: {id: [_lycra_subject.id]}}}).results.first
        end

        def indexed
          _indexed&._source&.to_h
        end

        def indexed?
          !!indexed
        end

        def reload
          super if defined?(super)
          @indexed = nil
          self
        end

        def inspect
          if @resolved
            "#<#{self.class.name} index: #{index_name}, document: #{document_type}, #{resolved.map { |key,attr| "#{key}: #{attr.to_json}"}.join(', ')}>"
          elsif @indexed
            "#<#{self.class.name} index: #{index_name}, document: #{document_type}, #{indexed.map { |key,attr| "#{key}: #{attr.to_json}"}.join(', ')}>"
          else
            "#<#{self.class.name} index: #{index_name}, document: #{document_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')}>"
          end
        end
      end
    end
  end
end
