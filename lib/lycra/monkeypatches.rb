# This is for awesome_print, which wants a to_hash method on objects to print
# them out in a console.

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
