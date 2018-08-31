class BaseSerializer < LycraSerializer
  attribute! :gid, types.integer, :id, 'Global ID of this object'
end

class VehicleSerializer < BaseSerializer
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
    resolve     ->(obj, arg, ctx) do
      "#{obj.name} #{obj.description}"
    end
  end
end
