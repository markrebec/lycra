class VehicleDocument < Lycra::Document::Base
  attribute :slug,
            types.text,
            'A unique slug'

  attribute name: :name,
            type: types.text,
            description: 'The name of the vehicle'

  attribute! do
    name :description
    type types.text
    description 'A description of the vehicle'
  end

  attribute :summary,
            types.text,
            'The first description',
            ->(obj,arg,ctx) { "first" },
            name: :summary,
            type: types.text,
            description: 'The second description',
            resolve: ->(obj,arg,ctx) { "second" },
            mapping: {index: :not_analyzed} do

    name        :summary
    type        types.text
    description 'The third description'
    mappings    ({index: :not_analyzed})
    resolve     ->(obj, arg, ctx) do
      "#{obj.name} #{obj.description}"
    end
  end
end
