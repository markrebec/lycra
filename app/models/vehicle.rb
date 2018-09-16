class Vehicle < ActiveRecord::Base
  include Lycra::Serializer::Model
  include Lycra::Decorator::Model
  include Lycra::Document::Model
end
