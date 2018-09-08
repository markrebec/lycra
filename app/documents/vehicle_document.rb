class VehicleDocument < ApplicationDocument
  #settings index: { number_of_shards: 1 }
  #mappings dynamic: 'false'

  #attribute! :id, types.integer, 'A unique identifier'

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

  attribute :summary, types.text do
    description 'The third description'
    mappings    ({index: 'not_analyzed'})
    resolve     ->(subj, args, ctxt) do
      "#{subj.name} #{subj.description}"
    end
  end
end
