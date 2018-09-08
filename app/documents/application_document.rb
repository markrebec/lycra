class ApplicationDocument
  include Lycra::Document

  attribute! :gid, types.integer, :id, 'Global ID of this object'

  def initialize(subject)
    @subject = subject
  end
end
