# TODO move this to LycraDocument / LycraSerializer ?
module Lycra
  module Document
    class Base
      include Document

      def initialize(subject)
        @_lycra_subject = subject
      end
    end
  end
end
