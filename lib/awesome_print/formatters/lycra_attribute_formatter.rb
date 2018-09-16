module AwesomePrint
  module Formatters
    class LycraAttributeFormatter < BaseFormatter
      attr_reader :attribute, :inspector, :options, :padding
      # TODO dynamic padding based on key length (maybe squash this back into
      # the collection class)
      # TODO mappings (maybe refactor attribute(s) to accept the document and
      # behave differently if they're a document attribute or not)

      def initialize(attribute, inspector, padding: 11)
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
            "#{attribute.required ? name.green : name.cyan} #{attribute.type.type.blue} #{resolver.yellowish}"
        end

        def description
          attribute.description || "No description"
        end

        def resolver
          attribute.resolver.is_a?(Symbol) ? "method" : "proc"
        end

        def mappings
          Inspector.new(options.merge({multiline: false})).awesome(attribute.mappings)
        end
    end
  end
end
