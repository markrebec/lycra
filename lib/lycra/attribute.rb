module Lycra
  class Attribute
    attr_reader :name, :type, :mappings, :description, :resolver

    # TODO make mappings kwargs?
    def initialize(name, type=nil, mappings={}, &block)
      @name = name
      self.type(type)
      self.mappings(mappings)
      @resolver = -> (obj, args, ctx) { obj.send(name) }

      instance_exec &block if block_given?
    end

    def type(type=nil)
      @type = Elasticsearch::Persistence::Model::Utils.lookup_type(type) if type
      @type
    end

    def mappings(mappings=nil)
      # TODO validate mappings
      @mappings = mappings if mappings
      @mappings# ||= {}
    end

    def description(description=nil)
      @description = description if description
      @description
    end

    def resolve(resolver=nil, &block)
      @resolver = resolver if resolver
      @resolver = block if block_given?
      @resolver
    end

    def resolve!(obj, *args, **ctx)
      resolver.call(obj, args, ctx)
    end
  end
end
