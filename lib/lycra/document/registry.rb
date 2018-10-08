module Lycra
  module Document
    class Registry
      class << self
        def __instance
          @instance ||= new
        end

        def add(klass)
          __instance.add(klass)
        end

        def all
          __instance.documents
        end

        def abstract
          __instance.documents.select(&:abstract?)
        end

        def concrete
          __instance.documents.reject(&:abstract?)
        end
      end

      def initialize
        @documents = []
      end

      def add(klass)
        @documents << klass
      end

      def documents
        @documents.dup
      end
    end
  end
end
