# Lycra

## Usage Examples

### Simple

```ruby
class Vehicle < ApplicationRecord
  # attributes:
  #   name string
  #   slug string
  #   speed integer
  #   wheels integer
  #   passengers integer
  #   description text
end

class VehicleDocument
  include Lycra::Document

  # a siple required attribute
  attribute! :id, types.integer

  # a simple attribute with a description
  attribute :name, types.text, 'An optional description of the attribute'

  # an attribute with custom mappings for elasticsearch
  attribute :slug, types.text, mappings: {index: :not_analyzed}

  # an attribute with a symbol indicating the method to call on your model
  attribute :top_speed, types.integer, :speed

  # an attribute using block syntax to define itself with a custom resolver
  attribute :wheels do
    type types.integer
    description 'An optional description of the attribute'

    resolve ->(model, args, context) do
      model.wheels # this just calls the wheels method but you can do anything in here
    end
  end

  # an attribute with an inline resolver
  attribute :max_passengers,
            types.integer,
            ->(mdl, arg, ctx) { mdl.passengers },
            'An optional description of the attribute',
            mappings: {index: :not_analyzed}

  # a simple attribute defining everything in a block, falling back on defaults
  attribute do
    name :description
    type types.text
  end
end
```

### STI

```ruby
class Vehicle < ApplicationRecord
  # attributes:
  #   type string
  #   name string
  #   slug string
  #   speed integer
  #   wheels integer
  #   passengers integer
  #   description text
end

class Car < Vehicle; end
class Truck < Vehicle; end
```

#### Shared Index

```ruby
class VehicleDocument
  include Lycra::Document

  parent! # TODO need to implement this (and come up with a better name)

  attribute :name,        types.text
  attribute :slug,        types.text
  attribute :speed,       types.integer
  attribute :wheels,      types.integer
  attribute :passengers,  types.integer
  attribute :description, types.text
end

class CarDocument < VehicleDocument
  # index_name will be "vehicles"
  # document_type will be "vehicle"

  attribute :passengers, types.integer do
    # ... do some custom stuff for an attribute for cars specifically ...
  end
end

class TruckDocument < VehicleDocument
  # index_name will be "vehicles"
  # document_type will be "vehicle"

  attribute :passengers, types.integer do
    # ... do some custom stuff for an attribute for trucks specifically ...
  end
end
```

### Separate Indices

```ruby
class VehicleDocument
  include Lycra::Document

  attribute :name,        types.text
  attribute :slug,        types.text
  attribute :speed,       types.integer
  attribute :wheels,      types.integer
  attribute :passengers,  types.integer
  attribute :description, types.text
end

class CarDocument < VehicleDocument
  # index_name will be "cars"
  # document_type will be "car"

  attribute :passengers, types.integer do
    # ... do some custom stuff for an attribute for cars specifically ...
  end
end

class TruckDocument < VehicleDocument
  # index_name will be "trucks"
  # document_type will be "truck"

  attribute :passengers, types.integer do
    # ... do some custom stuff for an attribute for trucks specifically ...
  end
end
```
