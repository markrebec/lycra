module Lycra
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, Elasticsearch::Model
      base.send :include, Elasticsearch::Model::Callbacks

      base.send :lycra_document

      base.send :delegate, :as_indexed_json, to: :lycra_document
    end

    def lycra_document
      self.class.lycra_document.new(self)
    end

    module ClassMethods
      def index_name(idx=nil)
        lycra_document.index_name idx
      end

      def document_type(doctype=nil)
        lycra_document.document_type doctype
      end

      def mapping(options={}, &block)
        lycra_document.mapping options, &block
      end
      alias_method :mappings, :mapping

      def lycra_document(klass=nil)
        if klass.present?
          if klass.respond_to?(:constantize)
            @lycra_document = klass.constantize.new(self)
          else
            @lycra_document = klass.new(self)
          end
        end

        @lycra_document ||= lycra_document_klass.new(self)
      end

      def lycra_document_klass
        begin
          return "#{self.name}Document".constantize
        rescue NameError => e
          # noop, we just continue
        end

        if respond_to?(:base_class) && self.base_class.name != self.name
          begin
            return "#{self.base_class.name}Document".constantize
          rescue NameError => e
            # noop, we just continue
          end
        end

        raise Lycra::DocumentNotFoundError.new(self)
      end
    end
  end
end
