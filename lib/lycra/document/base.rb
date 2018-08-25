module Lycra
  module Document
    class Base
      def self.inherited(base)
        base.send :include, Lycra::Document
      end

      def initialize(subject)
        @_lycra_subject = subject
      end
    end
  end
end
