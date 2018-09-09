class ApplicationDocument
  include Lycra::Document

  attribute! :gid, types.integer, :id, 'Global ID of this object'

end
