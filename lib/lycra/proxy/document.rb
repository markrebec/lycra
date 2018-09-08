module Lycra
  module Proxy
    # TODO separate out ModelDocumentProxy (model-backed) and DocumentProxy (generic serializer style documents)
    module Document
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
        delegate :index_name, :document_type, :subject_type, :import, :search, to: :__lycra__

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

        def as_json(options={})
          { index: index_name,
            document: document_type,
            subject: subject_type.name }
            .merge(attributes.map { |k,a| [a.name, a.type.type] }.to_h)
            .as_json(options)
        end

        def inspect
          "#{name}(index: #{index_name}, document: #{document_type}, subject: #{subject_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')})"
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

        def as_json(options={})
          hash = { index: self.class.index_name,
                   document: self.class.document_type,
                   subject: self.class.subject_type.name }

          if @resolved
            hash.merge!(resolved.map { |k,a| [k, a.as_json] }.to_h)
          elsif @indexed
            hash.merge!(indexed.map { |k,a| [k, a.as_json] }.to_h)
          else
            hash.merge!(attributes.map { |k,a| [a.name, a.type.type] }.to_h)
          end

          hash.as_json(options)
        end

        def inspect
          if @resolved
            "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, subject: #{self.class.subject_type}, #{resolved.map { |key,attr| "#{key}: #{attr.to_json}"}.join(', ')}>"
          elsif @indexed
            "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, subject: #{self.class.subject_type}, #{indexed.map { |key,attr| "#{key}: #{attr.to_json}"}.join(', ')}>"
          else
            "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, subject: #{self.class.subject_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')}>"
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

        # this is copying their (annoying) pattern
        class_eval do
          include ::Elasticsearch::Model::Indexing::ClassMethods
          include ::Elasticsearch::Model::Searching::ClassMethods
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

        def subject_type(model=nil)
          @_lycra_subject_type = model if model
          @_lycra_subject_type ||= (target.name.gsub(/Document\Z/, '').constantize rescue nil)
        end

        def subject_type=(model)
          subject_type model
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
        delegate :index_name, :document_type, :subject_type, to: :klass_proxy

        # this is copying their (annoying) pattern
        class_eval do
          include ::Elasticsearch::Model::Indexing::InstanceMethods
        end

        def klass
          target.class
        end

        def klass_proxy
          klass.__lycra__
        end
      end
    end
  end
end
