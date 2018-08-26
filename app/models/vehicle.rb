require 'elasticsearch/model'

class Vehicle < ActiveRecord::Base
  include Elasticsearch::Model

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :slug, type: 'text'
      indexes :name, type: 'text'
      indexes :description, type: 'text'
      indexes :summary, type: 'text', index: 'not_analyzed'
    end
  end

  def summary
    "#{name} #{description}"
  end

  def as_indexed_json(options={})
    VehicleDocument.resolve!(self)
  end
end
