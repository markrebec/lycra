module AwesomePrint
  module Formatters
    class LycraAttributesFormatter < HashFormatter
      attr_reader :attributes, :inspector, :options

      def initialize(attributes, inspector)
        @attributes = attributes
        @inspector = inspector
        @options = inspector.options
      end

      def format
        padding = attributes.keys.map { |k| k.to_s.length }.max
        attrs = attributes.values.map do |attr|
          inspector.awesome(attr)
        end

        if options[:multiline]
          "#{attributes.to_s} {\n#{attrs.join("\n")}\n}"
        else
          "#{attributes.to_s} { #{attrs.join(", ")} }"
        end
      end
    end
  end
end
