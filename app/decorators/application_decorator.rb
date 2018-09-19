class ApplicationDecorator
  include Lycra::Decorator

  abstract!

  attribute! :gid, types.integer, :id, 'Global ID of this object'
end
