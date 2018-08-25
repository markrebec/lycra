module Lycra
  class Attribute
    attr_reader :name, :type, :mappings, :description, :resolver, :resolved

    def self.type_for(type)
      case
        when type == String
          'text'
        when type == Integer
          'integer'
        when type == Float
          'float'
        when type == Date || type == Time || type == DateTime
          'date'
        when type == Hash
          'object'
        when type == Array # makes some pretty strong assumptions about using the nested data type...
          'nested'
        when type == Lycra::Text
          'text'
        when type == Lycra::Boolean
          'boolean'
        when type.is_a?(String) || type.is_a?(Symbol) # allow for all the variations of types like long, double, half_float, etc. https://www.elastic.co/guide/en/elasticsearch/reference/5.5/mapping-types.html
          type.to_s
      end
    end

    def initialize(name, type=nil, *args, **opts, &block)
      @name = name
      @type = type
      @mappings = opts[:mappings] || {}

      @resolver = args.first { |arg| arg.is_a?(Proc) || arg.is_a?(Symbol) }
      @resolver ||= -> (obj, arg, ctx) { obj.send(name) }

      instance_exec &block if block_given?
    end

    def type(type=nil)
      @type = type if type
      @type
    end

    def mappings(mappings=nil)
      @mappings = mappings if mappings
      {type: self.class.type_for(type)}.merge(@mappings || {})
    end

    def description(description=nil)
      @description = description if description
      @description
    end

    def resolve!(obj, *args, **ctx)
      return @resolved unless @resolved.nil?

      if resolver.is_a?(Proc)
        @resolved = resolver.call(obj, args, ctx)
      elsif resolver.is_a?(Symbol)
        @resolved = obj.send(resolver)
      end

      raise Lycra::AttributeError, "Invalid value #{@resolved} (#{@resolved.class.name}) for type #{type} in field #{name} on #{obj}" unless valid_for_type?(@resolved)

      @resolved
    end

    private

    def resolve(resolver=nil, &block)
      @resolver = resolver if resolver
      @resolver = block if block_given?
      @resolver
    end

    def valid_for_type?(value)
      return true if value.nil?

      case
        when type == Array
          # TODO need to account for arrays that aren't intended to be used as :nested JSON data, since ES handles them sorta seamlessly
          value.is_a?(Array) && (value.empty? || value.first.is_a?(Hash)) # need to do better than value.first here
        when type == String
          value.is_a?(String)
        when type == Integer
          value.is_a?(Integer)
        when type == Float
          value.is_a?(Float)
        when type == Date || type == Time || type == DateTime
          value.is_a?(Date) || value.is_a?(Time) || value.is_a?(DateTime)
        when type == Hash
          value.is_a?(Hash)
        when type == Lycra::Text
          value.is_a?(String)
        when type == Lycra::Boolean
          value.in?([true, false])
        else
          true # for all the miscellaneous data types
      end
    end
  end
end