module Lycra
  module Types
    class Type
      attr_reader :value

      def self.klasses(*klasses)
        @_klasses = klasses unless klasses.empty?
        @_klasses || []
      end

      def self.type(type=nil)
        @_type = type if type
        @_type ||= self.name.demodulize.underscore
      end

      def self.valid?(value, required=false)
        return false if required && value.nil?
        return true  if value.nil?
        klasses.any? { |klass| value.is_a?(klass) }
      end

      def self.transform(value)
        value # noop by default
      end

      def initialize(value)
        @value = value
      end

      def type(type=nil)
        @type = type if type
        @type ||= self.class.type
      end

      def valid?(required=false)
        @valid ||= self.class.valid?(@value, required)
      end

      def transform
        @transformed ||= self.class.transform(@value)
      end
    end

    class Text < Type
      klasses ::String, ::Enumerable
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
      def self.valid?(value, required=false)
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

      def self.valid?(value, required=false)
        return true if super(value)
        value.respond_to?(:to_h)
      end
    end

    def self.object
      Object
    end

    class Nested < Type
      def self.valid?(value, required=false)
        return true if value.nil?
        value.respond_to?(:each)
      end
    end

    def self.nested
      Nested
    end
  end
end
