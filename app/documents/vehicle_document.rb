class VehicleDocument < Lycra::Document::Base
  attribute :slug,
            String,
            'A unique slug'

  attribute name: :name,
            type: String,
            description: 'The name of the vehicle'

  attribute do
    name :description
    type Lycra::Text
    description 'A description of the vehicle'
  end

  attribute :summary,
            Lycra::Text,
            'The first description',
            ->(obj,arg,ctx) { "first" },
            name: :summary,
            type: Lycra::Text,
            description: 'The second description',
            resolve: ->(obj,arg,ctx) { "second" },
            mapping: {index: :not_analyzed} do

    name        :summary
    type        Lycra::Text
    description 'The third description'
    mappings    ({index: :not_analyzed})
    resolve     ->(obj, arg, ctx) do
      "#{obj.name} #{obj.description}"
    end
  end
end
