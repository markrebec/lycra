module Lycra
  module Document
    class Registry
      include Enumerable

      class << self
        delegate :add, :documents, :to_a, to: :__instance

        def __instance
          @instance ||= new
        end

        def all
          new(documents.reject(&:abstract?))
        end

        def abstract
          new(documents.select(&:abstract?))
        end
      end

      attr_reader :documents
      delegate :each, to: :documents

      def initialize(documents=[])
        @documents = documents
      end

      def add(klass)
        @documents << klass
      end

      def method_missing(meth, *args, **opts, &block)
        documents.map { |doc| doc.send(meth, *args, **opts, &block) }
      end
    end
  end
end
