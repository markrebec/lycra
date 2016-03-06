require 'spec_helper'

RSpec.describe Lycra::Query do
  subject { described_class.new(Person) }

  describe '#initialize' do
    it 'sets the model attribute' do
      expect(subject.model).to eq(Person)
    end
  end

  describe '#model' do
    it 'returns the model class' do
      expect(subject.model).to eq(Person)
    end
  end

  describe '#term' do
    subject { described_class.new(Person, term: 'foo') }

    it 'returns the term' do
      expect(subject.term).to eq('foo')
    end
  end

  describe '#query' do
    subject { described_class.new(Person, query: {foo: :bar}) }

    it 'returns the query hash' do
      expect(subject.query).to eq({foo: :bar})
    end
  end

  describe '#filters' do
    subject { described_class.new(Person, filters: {foo: :bar}) }

    it 'returns the filters hash' do
      expect(subject.filters).to eq({foo: :bar})
    end
  end

  describe '#facets' do
    subject { described_class.new(Person, facets: {foo: :bar}) }

    it 'returns the facets hash' do
      expect(subject.facets).to eq({foo: :bar})
    end
  end

  describe '#as_json' do
    it 'returns a hash' do
      expect(subject.as_json).to be_a(Hash)
    end

    it 'returns a hash of the attributes' do
      expect(subject.as_json).to eq({model: 'Person', term: nil, query: {}, filters: {}, facets: {}})
    end
  end

  describe '#index' do
    it 'returns the model index name' do
      expect(subject.index).to eq(Person.index_name)
    end
  end

  describe '#execute' do
    let(:people) { 100.times.map { |i| build(:person, id: (i+1)) } }
    before do
      Person.import(people, force: true)
    end

    it '#TODO' do
    end
  end
end
