require 'elasticsearch/model'

class Vehicle < ActiveRecord::Base
  include Elasticsearch::Model

  def as_indexed_json(options={})
    VehicleDocument.resolve!(self)
  end
end
