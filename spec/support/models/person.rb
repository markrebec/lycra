class Person
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Validations
  include Elasticsearch::Model

  index_name :lycra

  attr_accessor :id, :name, :email, :age
  validates :id, :name, :email, presence: true

  def as_json(opts={})
    { id: id,
      name: name,
      email: email,
      age: age }
  end
end
