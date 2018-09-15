module AwesomePrint
  module LycraAttributes
    def self.included(base)
      base.send :alias_method, :cast_without_lycra_attributes, :cast
      base.send :alias_method, :cast, :cast_with_lycra_attributes
    end

    def cast_with_lycra_attributes(object, type)
      cast = cast_without_lycra_attributes(object, type)
      return cast unless defined?(::Lycra::Attributes::Collection)

      if object.is_a?(::Lycra::Attributes::Collection)
        cast = :lycra_attributes
      end

      cast
    end

    def awesome_lycra_attributes(object)
      pad = object.keys.map { |k| k.to_s.length }.max
      attrs = object.values.map do |attr|
        name = attr.name.to_s.rjust(pad, ' ')
        indent = (pad + 1).times.map { ' ' }.join('')
        str = <<~AWESOME
          #{attr.required ? name.green : name.cyan} #{attr.type.type.blue}
          #{indent}#{attr.description || "No description"}
          #{indent}#{attr.resolver.is_a?(Symbol) ? "##{attr.resolver.to_s}".yellowish : attr.resolver.to_s.yellowish}
        AWESOME
      end
      attrs.join("\n")
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::LycraAttributes)
