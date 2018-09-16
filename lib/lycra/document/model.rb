module Lycra
  module Document
    module Model
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        delegate :__lycra__, :index_name, :document_type, :import, :search, to: :document

        def document(klass=nil)
          @_lycra_document = klass if klass
          @_lycra_document || ("#{name}Document".constantize rescue nil)
        end

        def document=(klass)
          document klass
        end
      end

      module InstanceMethods
        delegate :__lycra__, :as_indexed_json, :indexed, :indexed?, :index!, to: :document

        def reload
          @document = nil
          super
        end

        def document(document_class=nil)
          return document_class.new(self) if document_class
          @document ||= self.class.document.new(self)
        end
      end
    end
  end
end
