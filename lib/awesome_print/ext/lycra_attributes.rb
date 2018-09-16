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
      Formatters::LycraAttributesFormatter.new(object, @inspector).format
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::LycraAttributes)
