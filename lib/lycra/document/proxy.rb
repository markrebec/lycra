module Lycra
  module Document
    # TODO separate out ModelDocumentProxy (model-backed) and DocumentProxy (generic serializer style documents)
    module Proxy
      def self.included(base)
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

          class << self
            delegate :import, :search, to: :__lycra__
          end

          self.__lycra__.class_eval do
            include  ::Elasticsearch::Model::Importing::ClassMethods
            include  ::Elasticsearch::Model::Adapter.from_class(base).importing_mixin
          end
        end
      end

      module Base
        attr_reader :target
        delegate :settings, :mappings, :index_name, :document_type, :document_model, to: :target

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
          target.send(meth, *args, &block) if target.respond_to?(meth)
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
