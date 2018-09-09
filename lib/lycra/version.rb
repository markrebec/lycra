module Lycra
  module Version
    MAJOR = '5'
    MINOR = '0'
    PATCH = '0'
    VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

    class << self
      def inspect
        VERSION
      end
    end
  end
end
