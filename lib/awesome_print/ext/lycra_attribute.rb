module AwesomePrint
  module LycraAttribute
    def self.included(base)
      base.send :alias_method, :cast_without_lycra_attribute, :cast
      base.send :alias_method, :cast, :cast_with_lycra_attribute
    end

    def cast_with_lycra_attribute(object, type)
      cast = cast_without_lycra_attribute(object, type)
      return cast unless defined?(::Lycra::Attributes::Attribute)

      if object.is_a?(::Lycra::Attributes::Attribute)
        cast = :lycra_attribute
      end

      cast
    end

    def awesome_lycra_attribute(object)
      Formatters::LycraAttributeFormatter.new(object, @inspector).format
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::LycraAttribute)
