# This is for awesome_print, which wants a to_hash method on objects to print
# them out.

require 'elasticsearch/model/response/result'

module Elasticsearch
  module Model
    module Response
      class Result
        def to_hash
          to_h
        end
      end
    end
  end
end

# The Problem:
#
# https://github.com/elastic/elasticsearch-rails/issues/421
#
# We create our indices with a timestamp, then alias the basename (without the timestamp) to the timestamped index. When
# you ask the elasticsearch-model gem for records (instead of results), and it tries to use your models to look them up,
# it decides which model to use based on the index name and document type. This is a problem for us because our documents
# use the alias name (i.e. 'my-index') as their index name, but the hits that come back when searching use the timestamped
# index name (i.e. 'my-index-123456789'), which don't match up using the `==` operator in the original implementation of
# this method.

# The Solution:
#
# Instead of checking whether the hit's index name and the model's index name are exactly equal, we use a simple regex pattern
# to match the index names against each other. The regex pattern used below makes the timestamp optional, and allows for both
# 'my-index' and 'my-index-123456789' to match against 'my-index'

# TODO
# REMOVE THIS AFTER CREATING OUR OWN MULTIMODEL
=begin
module Elasticsearch
  module Model
    module Adapter
      module Multiple
        module Records
          # Returns the class of the model corresponding to a specific `hit` in Elasticsearch results
          #
          # @see Elasticsearch::Model::Registry
          #
          # @api private
          #
          def __type_for_hit(hit)
            @@__types ||= {}

            @@__types[ "#{hit[:_index]}::#{hit[:_type]}" ] ||= begin
              Registry.all.detect do |model|
                # Original Implementation
                #model.index_name == hit[:_index] && model.document_type == hit[:_type]

                # Our Monkeypatch
                hit[:_index] =~ /\A#{model.index_name}(-\d+)?\Z/ && model.document_type == hit[:_type]
              end
            end
          end
        end
      end
    end
  end
end
=end
