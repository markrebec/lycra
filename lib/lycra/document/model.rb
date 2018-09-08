module Lycra
  module Document
    module Model
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        delegate :index_name, :document_type, :import, :search, to: :document

        def document(klass=nil)
          @_lycra_document = klass if klass
          @_lycra_document || ("#{name}Document".constantize rescue nil)
        end

        def document=(klass)
          document klass
        end
      end

      module InstanceMethods
        delegate :as_indexed_json, :indexed, :indexed?, :index!, to: :document

        def reload
          @document = nil
          super
        end

        def document
          @document ||= self.class.document.new(self)
        end
      end
    end
  end
end
