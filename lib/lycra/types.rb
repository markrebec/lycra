module Lycra
  module Types
    class Type
      attr_reader :value

      class << self
        def klasses(*klasses)
          @_klasses = klasses unless klasses.empty?
          @_klasses || []
        end

        def type(type=nil)
          @_type = type if type
          @_type ||= self.name.demodulize.underscore
        end
        alias_method :to_s, :type

        def valid?(value, required=false, nested=false)
          return false if required && value.nil?
          return true  if value.nil?
          return false if nested && !value.is_a?(Enumerable)
          return true  if nested && value.empty?
          if nested
            klasses.any? { |klass| value.all? { |val| val.is_a?(klass) } }
          else
            klasses.any? { |klass| value.is_a?(klass) }
          end
        end

        def transform(value)
          value # noop by default
        end
      end

      def initialize(value)
        @value = value
      end

      def type(type=nil)
        @type = type if type
        @type ||= self.class.type
      end

      def valid?(required=false, nested=false)
        @valid ||= self.class.valid?(@value, required, nested)
      end

      def transform
        @transformed ||= self.class.transform(@value)
      end
    end

    class Text < Type
      klasses ::String
    end

    def self.text
      Text
    end

    class Integer < Type
      klasses ::Integer
    end

    def self.integer
      Integer
    end

    class Float < Type
      klasses ::Float
    end

    def self.float
      Float
    end

    class Date < Type
      klasses ::Date, ::Time, ::DateTime
    end

    def self.date
      Date
    end

    class Boolean < Type
      def self.valid?(value, required=false, nested=false)
        [true, false, 0, 1, nil].include?(value)
      end

      def self.transform(value)
        return value if [true, false].include?(value)
        return true  if value == 1
        false # 0, nil
      end
    end

    def self.boolean
      Boolean
    end

    class Object < Type
      klasses ::Hash

      def self.valid?(value, required=false, nested=false)
        return true if super(value, required, nested)
        value.respond_to?(:to_h)
      end
    end

    def self.object
      Object
    end

    class Nested < Type
      def self.valid?(value, required=false, nested=false)
        return true if value.nil?
        value.respond_to?(:each)
      end
    end

    def self.nested
      Nested
    end
  end
end
