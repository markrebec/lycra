module Elasticsearch
  module Model
    module Adapter

      # An adapter for Lycra::Document-based models
      #
      # TODO separate out ModelDocumentProxy and DocumentProxy
      module LycraProxy

        Adapter.register self,
                         lambda { |klass| !!defined?(::Lycra::Document::Proxy) && klass.respond_to?(:ancestors) && klass.ancestors.include?(::Lycra::Document::Proxy) }

        module Records
          attr_writer :options

          def options
            @options ||= {}
          end

          # Returns an `ActiveRecord::Relation` instance
          #
          def records
            sql_records = klass.document_model.where(klass.document_model.primary_key => ids)
            sql_records = sql_records.includes(self.options[:includes]) if self.options[:includes]

            # Re-order records based on the order from Elasticsearch hits
            # by redefining `to_a`, unless the user has called `order()`
            #
            sql_records.instance_exec(response.response['hits']['hits']) do |hits|
              ar_records_method_name = :to_a
              ar_records_method_name = :records if defined?(::ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5

              define_singleton_method(ar_records_method_name) do
                if defined?(::ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 4
                  self.load
                else
                  self.__send__(:exec_queries)
                end
                @records.sort_by { |record| hits.index { |hit| hit['_id'].to_s == record.id.to_s } }
              end if self
            end

            sql_records
          end

          # Prevent clash with `ActiveSupport::Dependencies::Loadable`
          #
          def load
            records.__send__(:load)
          end

          # Intercept call to the `order` method, so we can ignore the order from Elasticsearch
          #
          def order(*args)
            sql_records = records.__send__ :order, *args

            # Redefine the `to_a` method to the original one
            #
            sql_records.instance_exec do
              define_singleton_method(:to_a) do
                if defined?(::ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 4
                  self.load
                else
                  self.__send__(:exec_queries)
                end
                @records
              end
            end

            sql_records
          end
        end

        module Callbacks
          # Lycra does not use callbacks directly on the documents
        end

        module Importing

          # Fetch batches of records from the database (used by the import method)
          #
          #
          # @see http://api.rubyonrails.org/classes/ActiveRecord/Batches.html ActiveRecord::Batches.find_in_batches
          #
          def __find_in_batches(options={}, &block)
            query = options.delete(:query)
            named_scope = options.delete(:scope)
            preprocess = options.delete(:preprocess)

            scope = document_model
            scope = scope.__send__(named_scope) if named_scope
            scope = scope.instance_exec(&query) if query

            scope.find_in_batches(options) do |batch|
              yield (preprocess ? self.__send__(preprocess, batch) : batch)
            end
          end

          def __transform
            lambda do |model|
              json_data = begin
                if model.respond_to?(:model_document)
                  # TODO model_document.as_indexed_json(model)
                else
                  begin
                    "#{model.class.name}Document".constantize.as_indexed_json(model)
                  rescue
                    raise "Unable to locate a document class for the #{model.class.name} model"
                  end
                end
              end

              { index: { _id: model.id, data: json_data } }
            end
          end
        end
      end
    end
  end
end
