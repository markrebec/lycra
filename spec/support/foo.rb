#
# a document defining mappings, using the Lycra::Document mixin
#

  class FooSubject
    def foo
      'foo'
    end

    def bar
      "BAR"
    end
  end

  class Foo
    include Lycra::Document

    def initialize(*args, **opts, &block)
      @_lycra_subject = args.first
    end

    attribute :foo, String

    attribute :bar, Integer do
      resolve ->(obj, arg, ctx) do
        return 35
      end
    end

    attribute :baz do
      type String
      resolve do |obj, arg, ctx|
        "baz"
      end
    end

    attribute :blah, Integer, ->(obj, arg, ctx) { 35 }
    attribute :yadda, String, :bar

    attribute :bad do
      type String
      resolve ->(obj, arg, ctx) do
        return '35'
      end
    end
  end

#
# a document defining mappings, inheriting from Lycra::Document::Base
#

  class BarSubject
    def foo
      'bar'
    end

    def bar
      "FOO"
    end
  end

  class Bar < Lycra::Document::Base
    attribute :foo, String

    attribute :bar, Integer do
      resolve ->(obj, arg, ctx) do
        return 35
      end
    end

    attribute :baz do
      type String
      resolve do |obj, arg, ctx|
        "baz"
      end
    end

    attribute :blah, Integer, ->(obj, arg, ctx) { 35 }
    attribute :yadda, String do
      resolve :bar
    end

    attribute :bad do
      type String
      resolve ->(obj, arg, ctx) do
        return '35'
      end
    end
  end

=begin

#
# an active record model, with mappings inline (could be moved to concern)
#

  class Foo < ApplicationRecord
    include Elasticsearch::Model
    include Lycra::Model
  end


#
# a document defining mappings, with records backed by a corresponding model
# and/or
# an active record model, with mappings defined in a corresponding document
#
# this can be a one- or two-way relationship depending on how you want to use it

  class FooDocument
    include Lycra::Document # or... Lycra::Model::Document to specify a document w/ a backing model?
  end

  class Foo < ApplicationRecord
    include Lycra::Document::Model # specify a model backed by a document
  end

=end
