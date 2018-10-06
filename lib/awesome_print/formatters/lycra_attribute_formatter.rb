module AwesomePrint
  module Formatters
    class LycraAttributeFormatter < BaseFormatter
      attr_reader :attribute, :inspector, :options, :padding
      # TODO mappings (maybe refactor attribute(s) to accept the document and
      # behave differently if they're a document attribute or not)

      def initialize(attribute, inspector, padding: 0)
        @attribute = attribute
        @inspector = inspector
        @options = inspector.options
        @padding = padding
      end

      def format
        if options[:multiline]
          [ 
            name_and_type,
            indent + (' ' * (padding + 1)) + description,
            #indent + (' ' * (padding + 1)) + mappings
          ].join("\n")
        else
          "#{name_and_type} #{description}" #{mappings}"
        end
      end

      private

        def name_and_type
          name = align(attribute.name.to_s, indentation + padding)
          name = attribute.required? ? name.green : name.cyan
          type = attribute.type.type
          type = attribute.nested? ? "[#{type}]" : "#{type}"
          "#{name} #{type.blue} #{resolver}"
        end

        def description
          attribute.description || "No description"
        end

        def resolver
          if attribute.resolver.is_a?(Symbol)
            if attribute.klass.instance_methods.include?(attribute.resolver)
              (attribute.klass.name.yellowish + "##{attribute.resolver.to_s}".purpleish)
            else
              (attribute.klass.subject_type.name.yellowish + "##{attribute.resolver.to_s}".purpleish)
            end
          else
            attribute.resolver.to_s.yellowish
          end
        end

        def mappings
          Inspector.new(options.merge({multiline: false})).awesome(attribute.mappings)
        end
    end
  end
end
