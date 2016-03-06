class Person
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Validations
  include Elasticsearch::Model

  index_name :lycra

  attr_accessor :id, :name, :email, :age
  validates :id, :name, :email, presence: true

  def as_json(opts={})
    { id: id,
      name: name,
      email: email,
      age: age }
  end

  # TODO write a SpecModelAdapter for ActiveModel that implements __transform and __find_in_batches instead
  def self.import(records, options={})
    errors = []
    target_index = options.delete(:index) || index_name
    target_type = options.delete(:type) || document_type

    if options.delete(:force)
      __elasticsearch__.create_index! force: true, index: target_index
    elsif !__elasticsearch__.index_exists? index: target_index
      raise ArgumentError,
        "#{target_index} does not exist to be imported into. Use create_index! or the :force option to create it."
    end

    records.each_slice(2_000) do |recs|
      response = __elasticsearch__.client.bulk \
        index: target_index,
        type: target_type,
        body: recs.map { |rec| { index: { _id: rec.id, data: rec.__elasticsearch__.as_indexed_json } } }

      yield response if block_given?

      errors +=  response['items'].select { |k, v| k.values.first['error'] }
    end

    __elasticsearch__.refresh_index! if options.delete(:refresh)

    errors
  end
end
