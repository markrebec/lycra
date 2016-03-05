class Person
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Validations

  attr_accessor :name, :email, :age
  validates :name, :email, presence: true
end
