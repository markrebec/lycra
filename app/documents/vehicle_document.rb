class VehicleDocument < Lycra::Document::Base
  attribute :slug, String
  attribute :name, String
  attribute :description, Lycra::Text
  attribute :summary, Lycra::Text do
    resolve ->(obj, arg, ctx) do
      "#{obj.name} #{obj.description}"
    end
  end
end
