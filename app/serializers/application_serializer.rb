class ApplicationSerializer
  include Lycra::Serializer

  attribute! :gid, types.integer, :id, 'Global ID of this object'

end
