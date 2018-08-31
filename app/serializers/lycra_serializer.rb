# TODO do we need a Lycra::Serializer ?
class LycraSerializer
  include Lycra::Attributes

  def initialize(subject)
    @_lycra_subject = subject
  end
end
