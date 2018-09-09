class ApplicationDecorator
  include Lycra::Decorator

  attribute! :gid, types.integer, :id, 'Global ID of this object'

end
