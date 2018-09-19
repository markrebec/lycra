class ApplicationSerializer
  include Lycra::Serializer

  abstract!

  attribute! :gid, types.integer, :id, 'Global ID of this object'
end
