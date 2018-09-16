module Lycra
  module Attributes
    class Attribute
      attr_reader :resolved, :required, :klass

      def initialize(name=nil, type=nil, *args, **opts, &block)
        @name = name
        @name ||= opts[:name]

        @nested_type = type.is_a?(Array)
        @type = [type].flatten.compact.first
        @type ||= [opts[:type]].flatten.compact.first

        @klass = opts[:klass]

        @mappings = opts[:mappings] || opts[:mapping]

        @resolver = args.find { |arg| arg.is_a?(Proc) || arg.is_a?(Symbol) }
        @resolver = opts[:resolve] if opts.key?(:resolve)
        @resolver = opts[:resolver] if opts.key?(:resolver)

        @description = args.find { |arg| arg.is_a?(String) }
        @description = opts[:description] if opts.key?(:description)

        @required = opts[:required] || false
        @cache = opts[:cache] || false

        instance_exec &block if block_given?
      end

      def name(name=nil)
        @name = name if name
        @name
      end

      def type(type=nil)
        if type
          @nested_type = type.is_a?(Array)
          @type = [type].flatten.compact.first
        end
        @type
      end

      def nested?
        !!@nested_type
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

      def required?
        !!@required
      end

      def resolve!(subj, *args, **ctxt)
        @resolved ||= begin
          # TODO wrap this whole block in cache if caching is enabled
          if resolver.is_a?(Proc)
            result = resolver.call(subj, args, ctxt)
          elsif resolver.is_a?(Symbol)
            result = subj.send(resolver)
          end

          rslvd = type.new(result)

          unless rslvd.valid?(required?, nested?)
            rslvd_type = rslvd.type
            rslvd_type = "array[#{rslvd.type}]" if nested?
            raise Lycra::AttributeError,
              "Invalid value #{rslvd.value} (#{rslvd.value.class.name}) " +
              "for type '#{rslvd_type}' in field #{name} on #{subj}"
          end

          rslvd.transform
        end
      end

      def resolved?
        instance_variable_defined? :@resolved
      end

      def reload
        remove_instance_variable :@resolved
        self
      end

      def as_json(options={})
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
end
