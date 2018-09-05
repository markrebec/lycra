require 'lycra/indexing'

module Lycra
  module Document
    # TODO separate out ModelDocumentProxy (model-backed) and DocumentProxy (generic serializer style documents)
    module Proxy
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods

        base.class_eval do
          def self.__lycra__(&block)
            @__lycra__ ||= ClassProxy.new(self)
            @__lycra__.instance_eval(&block) if block_given?
            @__lycra__
          end

          def __lycra__(&block)
            @__lycra__ ||= InstanceProxy.new(self)
            @__lycra__.instance_eval(&block) if block_given?
            @__lycra__
          end

          self.__lycra__.class_eval do
            include  ::Elasticsearch::Model::Importing::ClassMethods
            include  ::Elasticsearch::Model::Adapter.from_class(base).importing_mixin
          end
        end
      end

      module ClassMethods
        delegate :index_name, :document_type, :document_model, :import, :search, to: :__lycra__

        def inherited(child)
          super if defined?(super)

          # resets the proxy so it gets recreated for the new class
          child.send :instance_variable_set, :@__lycra__, nil

          child.class_eval do
            self.__lycra__.class_eval do
              include  ::Elasticsearch::Model::Importing::ClassMethods
              include  ::Elasticsearch::Model::Adapter.from_class(child).importing_mixin
            end
          end
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

        def index!
          __lycra__.index_document
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
            "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, #{resolved.map { |key,attr| "#{key}: #{attr.to_json}"}.join(', ')}>"
          elsif @indexed
            "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, #{indexed.map { |key,attr| "#{key}: #{attr.to_json}"}.join(', ')}>"
          else
            "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')}>"
          end
        end
      end

      module Base
        attr_reader :target

        def initialize(target)
          @target = target
        end

        def client=(client)
          @client = client
        end
        
        def client
          @client ||= Lycra.client
        end

        def method_missing(meth, *args, &block)
          return target.send(meth, *args, &block) if target.respond_to?(meth)
          super
        end

        def respond_to?(meth, priv=false)
          target.respond_to?(meth, priv) || super
        end
      end

      class ClassProxy
        include Base

        # TODO this is copying their patter, but can't we just extend with these?
        class_eval do
          include  ::Elasticsearch::Model::Indexing::ClassMethods
          include  ::Elasticsearch::Model::Searching::ClassMethods
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
          @_lycra_document_type ||= target.name.demodulize.gsub(/Document\Z/, '').underscore
        end

        def document_type=(type)
          document_type type
        end

        def document_model(model=nil)
          @_lycra_document_model = model if model
          @_lycra_document_model ||= (target.name.gsub(/Document\Z/, '').constantize rescue nil)
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
      end

      class InstanceProxy
        include Base

        # TODO this is copying their patter, but can't we just extend with these?
        class_eval do
          include ::Elasticsearch::Model::Indexing::InstanceMethods
        end

        def klass
          target.class
        end
      end
    end
  end
end
