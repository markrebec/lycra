module Lycra
  module Version
    MAJOR = '0'
    MINOR = '0'
    PATCH = '7'
    VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

    class << self
      def inspect
        VERSION
      end
    end
  end
end
