module Lycra
  class Attribute
    attr_reader :resolved, :required

    def initialize(name=nil, type=nil, *args, **opts, &block)
      @name = name
      @name ||= opts[:name]

      @type = type
      @type ||= opts[:type]

      @mappings = opts[:mappings] || opts[:mapping]

      @resolver = args.find { |arg| arg.is_a?(Proc) || arg.is_a?(Symbol) }
      @resolver = opts[:resolve] if opts.key?(:resolve)
      @resolver = opts[:resolver] if opts.key?(:resolver)

      @description = args.find { |arg| arg.is_a?(String) }
      @description = opts[:description] if opts.key?(:description)

      @required = opts[:required] || false

      instance_exec &block if block_given?
    end

    def name(name=nil)
      @name = name if name
      @name
    end

    def type(type=nil)
      @type = type if type
      @type
    end

    def mappings(mappings=nil)
      @mappings = mappings if mappings
      {type: type.type}.merge(@mappings || {})
    end
    alias_method :mapping, :mappings

    def description(description=nil)
      @description = description if description
      @description
    end

    def resolver
      @resolver ||= name.to_sym
    end

    def required!
      @required = true
    end

    def resolve!(obj, *args, **ctx)
      # don't memoize for now because it doesn't pick up model changes
      # TODO maybe compare the original value to @resolved if it exists
      # and refresh if it changed?
      #return @resolved.transform unless @resolved.nil?

      if resolver.is_a?(Proc)
        result = resolver.call(obj, args, ctx)
      elsif resolver.is_a?(Symbol)
        result = obj.send(resolver)
      end

      @resolved = type.new(result)

      raise Lycra::AttributeError, "Invalid value #{@resolved.value} (#{@resolved.value.class.name}) for type '#{@resolved.type}' in field #{name} on #{obj}" unless @resolved.valid?(@required)

      @resolved.transform
    end

    def as_json(opts={})
      {
        name: name,
        type: type.type,
        required: required,
        description: description,
        mappings: mappings,
        resolver: resolver.is_a?(Symbol) ? resolver : resolver.to_s
      }
    end

    private

    def resolve(resolver=nil, &block)
      @resolver = resolver if resolver
      @resolver = block if block_given?
      @resolver
    end

    def types
      Lycra::Types
    end
  end
end
