module Lycra
  String    = ::String
  Integer   = ::Integer
  Float     = ::Float
  Date      = ::Date
  Time      = ::Time
  DateTime  = ::DateTime
  Hash      = ::Hash
  Array     = ::Array
  class Text;     end
  class Boolean;  end
end

# easy access types as long as they don't interfere
Text    = Lycra::Text     unless defined?(Text)
Boolean = Lycra::Boolean  unless defined?(Boolean)
