class LycraDocument
  include Lycra::Document

  def initialize(subject)
    @_lycra_subject = subject
  end
end
