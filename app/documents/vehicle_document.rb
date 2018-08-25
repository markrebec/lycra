class VehicleDocument < Lycra::Document::Base
  attribute :slug,        String,       :slug,  'A unique slug'
  attribute :name,        String,               'The name of the vehicle'
  attribute :description, Lycra::Text,          'A description of the vehicle'

  attribute :summary,     Lycra::Text do
    description 'A concatenated summary for searching'

    resolve ->(obj, arg, ctx) do
      "#{obj.name} #{obj.description}"
    end
  end
end
