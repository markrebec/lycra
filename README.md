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

## IMPORT / ROTATE / REINDEX

All methods take a `batch_size: 200` (default) keyword argument and can accept a block which will be yielded each batch result as it is processed.

For example if you wanted to perform an import while displaying a progress bar:

```
importer = Lycra::Import.new # you can pass an array of documents, otherwise defaults to all documents
bar = ProgressBar.new(importer.total) # total number of records to be processed

importer.import(batch_size: 200) do |batch|
  bar.increment!(batch['items'].count) # batch is the result of the batch import
end
```

### Importing

`Lycra::Import.import` is used for (re)initializing new indices. It deletes and creates the index & alias, then perform a fresh import.

This will cause downtime as the index is being repopulated by the import.

### Rotating

`Lycra::Import.rotate` is used when index mappings are changed. It creates a new index, performs an import, then hot-swaps the alias to the new index.

When your mappings change, the index fingerprint will change, which requires that you create that new index and populate it.

The alias will continue pointing to your old index while the new one is being populated, and all search queries will cotinue to reference the alias. This allows your app to stay up using the old index until the new one is ready to be swapped in.

### Reindexing

`Lycra::Import.reindex` is used when data changes (but not mappings). It updates all documents in the index using bulk updates.

If your mappings have changed at all that means your index fingerprint will have changed, and you will need to use `import` then swap your aliases manually, or use to `rotate` to populate and swap in one shot.

## TODO / IDEAS

* import scope
* merge document+proxy
* caching
* solidify conventions around bang methods / better error handling and raising
* chainable search classes and DSL
* search scopes
* facets/helpers

```
# returns results
Vehicle.search('car')
Vehicle.search('car', filters: {published: true})
Vehicle.search(filters: {published: true})

# chainable
Vehicle.search
Vehicle.search.term('car')
Vehicle.search.filter(published: true)

# DSL
Vehicle.search do
  term 'car'
  filter published: true
end

Vehicle.search do
  term 'car' do
    filters do
      published true
    end
  end
end

# multi-index
Lycra.search
```
