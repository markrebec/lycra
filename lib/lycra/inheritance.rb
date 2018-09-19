module Lycra
  module Inheritance
    attr_accessor :abstract_class

    def self.extended(base)
      base.send :delegate, :abstract?, to: :class
    end

    def abstract!
      @abstract_class = true
    end

    def abstract?
      !!abstract_class
    end
  end
end
