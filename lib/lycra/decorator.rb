module Lycra
  module Decorator
    def self.included(base)
      base.send :include, Attributes
    end

    def as_json(options={})
      resolve!(subject).as_json(options)
    end

    def method_missing(meth, *args, &block)
      return attributes[meth].resolve!(subject, *args, &block) if attributes.key?(meth)
      return subject.send(meth, *args, &block) if subject && subject.respond_to?(meth)
      super
    end

    def respond_to?(meth, priv=false)
      attributes.key?(meth) || (subject && subject.respond_to?(meth, priv)) || super
    end
  end
end
