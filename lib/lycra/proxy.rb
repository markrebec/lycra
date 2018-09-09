module Lycra
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
      delegate :index_name, :document_type, :import, :search, to: :__lycra__

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
        "#{name}(index: #{index_name}, document: #{document_type}, subject: #{subject_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.type.type}"}.join(', ')})"
      end
    end

    module InstanceMethods
      delegate :index_name, :document_type, :subject_type, to: :class

      def as_indexed_json(options={})
        resolve!.as_json(options)
      end

      def index!
        @indexed = nil
        __lycra__.index_document
      end

      def _indexed
        @indexed ||= self.class.search({query: {terms: {id: [subject.id]}}}).results.first
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
        attr_str = "#{attributes.map { |key,attr| "#{key}: #{(resolved? && resolved[key].try(:to_json)) || (_indexed? && indexed[key.to_s].try(:to_json)) || attr.type.type}"}.join(', ')}>"
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

      def respond_to?(meth, priv=false)
        target.respond_to?(meth, priv) || super
      end
    end

    class ClassProxy
      include BaseProxy
      delegate :subject_type, to: :target

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
