module Lycra
  module Document
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
        delegate :index_name, :document_type, :create_index!, :delete_index!, :import, :search, to: :__lycra__

        def inherited(child)
          super if defined?(super)

          # resets the proxy so it gets recreated for the new class
          child.send :instance_variable_set, :@__lycra__, nil
          child.send :instance_variable_set, :@_lycra_import_scope, self.import_scope

          child.class_eval do
            self.__lycra__.class_eval do
              include  ::Elasticsearch::Model::Importing::ClassMethods
              include  ::Elasticsearch::Model::Adapter.from_class(child).importing_mixin
            end
          end
        end

        def import_scope(scope=nil, &block)
          @_lycra_import_scope = scope if scope
          @_lycra_import_scope = block if block_given?
          @_lycra_import_scope
        end

        def import_scope=(scope)
          import_scope scope
        end

        def as_indexed_json(subj, options={})
          resolve!(subj).as_json(options)
        end

        def as_json(options={})
          { index: index_name,
            document: document_type,
            subject: subject_type.name }
            .merge(attributes.map { |k,a| [a.name, a.type.type] }.to_h)
            .as_json(options)
        end

        def inspect
          "#{name}(index: #{index_name}, document: #{document_type}, subject: #{subject_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.nested? ? "[#{attr.type.type}]" : attr.type.type}"}.join(', ')})"
        end
      end

      module InstanceMethods
        delegate :index_name, :document_type, to: :class

        def as_indexed_json(options={})
          resolve!.as_json(options)
        end

        def index!
          raise Lycra::AbstractClassError, "Cannot index using an abstract class" if abstract?

          @indexed = nil
          __lycra__.index_document
        end

        def _indexed
          @indexed ||= self.class.search({query: {terms: {_id: [subject.id]}}}).results.first
        end

        def indexed
          _indexed&._source&.to_h
        end

        def indexed?
          !!indexed
        end

        def _indexed?
          !!@indexed
        end

        def reload
          super if defined?(super)
          @indexed = nil
          self
        end

        def as_json(options={})
          resolve! unless resolved?

          { index: self.class.index_name,
            document: self.class.document_type,
            subject: self.class.subject_type.name,
            resolved: resolved.map { |k,a| [k, a.as_json] }.to_h,
            indexed: indexed? && indexed.map { |k,a| [k, a.as_json] }.to_h }
            .as_json(options)
        end

        def inspect
          attr_str = "#{attributes.map { |key,attr| "#{key}: #{(resolved? && resolved[key].try(:to_json)) || (_indexed? && indexed[key.to_s].try(:to_json)) || (attr.nested? ? "[#{attr.type.type}]" : attr.type.type)}"}.join(', ')}>"
          "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, subject: #{self.class.subject_type}, #{attr_str}"
        end
      end

      module BaseProxy
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

        def respond_to_missing?(meth, priv=false)
          target.respond_to?(meth, priv) || super
        end
      end

      class ClassProxy
        include BaseProxy
        delegate :subject_type, :import_scope, to: :target

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

        def create_index!(options={})
          raise Lycra::AbstractClassError, "Cannot create using an abstract class" if abstract?
          super
        end

        def delete_index!(options={})
          raise Lycra::AbstractClassError, "Cannot delete using an abstract class" if abstract?
          super
        end

        def refresh_index!(options={})
          raise Lycra::AbstractClassError, "Cannot refresh using an abstract class" if abstract?
          super
        end

        def import(options={}, &block)
          raise Lycra::AbstractClassError, "Cannot import using an abstract class" if abstract?

          scope_hash = {}
          scope_hash[:scope] = import_scope if import_scope.is_a?(String) || import_scope.is_a?(Symbol)
          scope_hash[:query] = import_scope if import_scope.is_a?(Proc)
          options = scope_hash.merge(options)

          super(*args, **options, &block)
        end
      end

      class InstanceProxy
        include BaseProxy
        delegate :index_name, :document_type, to: :klass_proxy
        delegate :subject_type, to: :klass

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
