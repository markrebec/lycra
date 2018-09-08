class ApplicationDocument
  include Lycra::Document

  attribute! :gid, types.integer, :id, 'Global ID of this object'

  def initialize(subject)
    @_lycra_subject = subject
  end
end
