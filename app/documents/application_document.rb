class ApplicationDocument
  include Lycra::Document

  abstract!

  attribute! :gid, types.integer, :id, 'Global ID of this object'
end
