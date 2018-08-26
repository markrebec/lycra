require 'lycra/document/base'

module Lycra
  module Document
    def self.included(base)
      # generic enough to build simple serializers or whatever
      base.send :include, Attributes
      # elasticsearch specific
      base.send :include, Indexing
    end

    module Attributes
      def self.included(base)
        base.send :attr_accessor, :_lycra_subject
        base.send :extend, ClassMethods
        base.send :include, InstanceMethods
        base.send :delegate, :attributes, to: base
      end

      module ClassMethods
        def types
          Lycra::Types
        end

        def attribute(name=nil, type=nil, *args, **opts, &block)
          attrib = Attribute.new(name, type, *args, **opts, &block)
          attributes[attrib.name] = attrib
        end

        def attribute!(name=nil, type=nil, *args, **opts, &block)
          attribute(name, type, *args, **opts.merge({required: true}), &block)
        end

        def attributes
          @_lycra_attributes ||= {}
        end

        def resolve!(obj, *args, **context)
          new(obj).resolve!(*args, **context)
        end
      end

      module InstanceMethods
        def resolve!(*args, **context)
          raise Lycra::MissingSubjectError.new(self) if _lycra_subject.nil?
          attributes.map do |key,attr|
            [ key, attr.resolve!(_lycra_subject, args, context) ]
          end.to_h
        end
      end
    end

    module Indexing
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :delegate, :document_type, :index_name,
                  :mapping, :mappings, :settings, to: base
      end

      module ClassMethods
        def document_type(type=nil)
          @_lycra_document_type = type if type
          @_lycra_document_type ||= name.demodulize.gsub(/Document\Z/, '')
        end

        def index_name(index=nil)
          @_lycra_index_name = index if index
          @_lycra_index_name ||= document_type.underscore.pluralize
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
    end
  end
end
