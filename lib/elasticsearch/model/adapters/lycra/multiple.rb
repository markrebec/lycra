module Elasticsearch
  module Model
    module Adapter
      module Lycra

        module Multiple
          Adapter.register self, lambda { |klass| klass.is_a? ::Lycra::Multidoc }

          module Records
            #def documents
            #  documents_by_type = __documents_by_type

            #  documents = response.response["hits"]["hits"].map do |hit|
            #    documents_by_type[ __type_for_hit(hit) ][ hit[:_id] ]
            #  end

            #  documents.compact
            #end

            def records
              documents_by_type = __documents_by_type

              records = response.response["hits"]["hits"].map do |hit|
                documents_by_type[ __type_for_hit(hit) ][ hit[:_id] ]#.subject
              end

              records.compact
            end

            def __documents_by_type
              result = __ids_by_type.map do |klass, ids|
                documents = __documents_for_klass(klass, ids)
                ids     = documents.map(&:id).map(&:to_s)
                mapped = [ klass, Hash[ids.zip(documents)] ]
                mapped
              end

              Hash[result]
            end

            def __documents_for_klass(klass, ids)
              return klass.subject_type.where(klass.primary_key => ids)
            end

            def __ids_by_type
              ids_by_type = {}

              response.response["hits"]["hits"].each do |hit|
                type = __type_for_hit(hit)
                ids_by_type[type] ||= []
                ids_by_type[type] << hit[:_id]
              end
              ids_by_type
            end

            def __type_for_hit(hit)
              @@__types ||= {}

              @@__types[ "#{hit[:_index]}::#{hit[:_type]}" ] ||= begin
                ::Lycra::Document::Registry.all.detect do |document|
                  hit[:_index] =~ /\A#{document.index_name}(-\d+)?\Z/ && document.document_type == hit[:_type]
                end
              end
            end
          end
        end
      end
    end
  end
end
