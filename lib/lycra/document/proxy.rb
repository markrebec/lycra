require 'lycra/document/registry'

module Lycra
  module Document
    module Proxy
      def self.included(base)
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods

        base.class_eval do
          def self.__lycra__(&block)
            @__lycra__ ||= ClassProxy.new(self)
            @__lycra__.instance_eval(&block) if block_given?
            @__lycra__
          end

          def __lycra__(&block)
            @__lycra__ ||= InstanceProxy.new(self)
            @__lycra__.instance_eval(&block) if block_given?
            @__lycra__
          end

          self.__lycra__.class_eval do
            include  ::Elasticsearch::Model::Importing::ClassMethods
            include  ::Elasticsearch::Model::Adapter.from_class(base).importing_mixin
          end

          Registry.add(base)
        end
      end

      module ClassMethods
        delegate :alias_name, :index_name, :document_type, :search,
          :alias_exists?, :index_exists?, :index_aliased?, :aliased_index,
          to: :__lycra__

        def inherited(child)
          super if defined?(super)

          # resets the proxy so it gets recreated for the new class
          child.send :instance_variable_set, :@__lycra__, nil
          child.send :instance_variable_set, :@_lycra_import_scope, self.import_scope

          child.class_eval do
            self.__lycra__.class_eval do
              include  ::Elasticsearch::Model::Importing::ClassMethods
              include  ::Elasticsearch::Model::Adapter.from_class(child).importing_mixin
            end
          end

          Registry.add(child)
        end

        def import_scope(scope=nil, &block)
          @_lycra_import_scope = scope if scope
          @_lycra_import_scope = block if block_given?
          @_lycra_import_scope
        end

        def import_scope=(scope)
          import_scope scope
        end

        def create_alias!(options={})
          raise Lycra::AbstractClassError, "Cannot create aliases using an abstract class" if abstract?
          __lycra__.create_alias!(options)
        end

        def create_alias(options={})
          create_alias!(options)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def create_index!(options={})
          raise Lycra::AbstractClassError, "Cannot create indices using an abstract class" if abstract?
          __lycra__.create_index!(options)
          __lycra__.create_alias!(options) unless alias_exists?
        end

        def create_index(options={})
          create_index!(options)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def delete_alias!(options={})
          raise Lycra::AbstractClassError, "Cannot delete aliases using an abstract class" if abstract?
          __lycra__.delete_alias!(options)
        end

        def delete_alias(options={})
          delete_alias!(options)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def delete_index!(options={})
          raise Lycra::AbstractClassError, "Cannot delete indices using an abstract class" if abstract?
          __lycra__.delete_alias!(options) if alias_exists?
          __lycra__.delete_index!(options)
        end

        def delete_index(options={})
          delete_index!(options)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def refresh_index!(options={})
          raise Lycra::AbstractClassError, "Cannot refresh indices using an abstract class" if abstract?
          __lycra__.refresh_index!(options)
        end

        def refresh_index(options={})
          refresh_index!(options)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def import!(options={}, &block)
          raise Lycra::AbstractClassError, "Cannot import using an abstract class" if abstract?

          options[:scope] ||= import_scope if import_scope.is_a?(String) || import_scope.is_a?(Symbol)
          options[:query] ||= import_scope if import_scope.is_a?(Proc)

          __lycra__.import(options, &block)
        end

        def import(options={}, &block)
          import!(options, &block)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def update!(options={}, &block)
          raise Lycra::AbstractClassError, "Cannot update using an abstract class" if abstract?

          scope = options[:scope] || options[:query] || import_scope
          if scope.is_a?(Proc)
            scope = subject_type.instance_exec(&scope)
          elsif scope.is_a?(String) || scope.is_a?(Symbol)
            scope = subject_type.send(scope)
          elsif scope.nil?
            scope = subject_type.all
          end

          scope.find_in_batches(batch_size: (options[:batch_size] || 200)).each do |batch|
            json_options = options.select { |k,v| [:only,:except].include?(k) }
            items = batch.map do |record|
              { update: {
                  _index: index_name,
                  _type: document_type,
                  _id: record.id,
                  data: {
                    doc: new(record).resolve!(json_options)
                  }.stringify_keys
                }.stringify_keys
              }.stringify_keys
            end

            updated = __lycra__.client.bulk(body: items)

            missing = updated['items'].map do |miss|
              if miss['update'].key?('error') &&
                 miss['update']['error']['type'] == 'document_missing_exception'

                update = miss['update']
                item = items.find { |i| i['update']['_id'].to_s == miss['update']['_id'] }['update']
                if json_options.empty?
                  data = item['data']['doc']
                else
                  data = new(subject_type.find(update['_id'])).resolve!
                end

                { index: {
                    _index: update['_index'],
                    _type: update['_type'],
                    _id: update['_id'],
                    data: data
                  }.stringify_keys
                }.stringify_keys
              else
                nil
              end
            end.compact

            if missing.count > 0
              indexed = __lycra__.client.bulk body: missing

              updated['items'] = updated['items'].map do |item|
                miss = indexed['items'].find { |i| i['index']['_id'] == item['update']['_id'] }
                miss || item
              end
            end

            yield(updated) if block_given?
          end

          return true
        end

        def update(options={}, &block)
          update!(options, &block)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def delete!(options={}, &block)
          raise Lycra::AbstractClassError, "Cannot delete using an abstract class" if abstract?

          scope = options[:scope] || options[:query] || import_scope
          if scope.is_a?(Proc)
            scope = subject_type.instance_exec(&scope)
          elsif scope.is_a?(String) || scope.is_a?(Symbol)
            scope = subject_type.send(scope)
          elsif scope.nil?
            scope = subject_type.all
          end

          scope.find_in_batches(batch_size: (options[:batch_size] || 200)).each do |batch|
            items = batch.map do |record|
              { delete: {
                  _index: index_name,
                  _type: document_type,
                  _id: record.id
                }.stringify_keys
              }.stringify_keys
            end

            deleted = __lycra__.client.bulk(body: items)

            yield(deleted) if block_given?
          end

          return true
        end

        def delete(options={}, &block)
          delete!(options, &block)
        rescue => e
          Lycra.configuration.logger.error(e.message)
          return false
        end

        def as_indexed_json(subj, options={})
          resolve!(subj).as_json(options)
        end

        def as_json(options={})
          { index: index_name,
            document: document_type,
            subject: subject_type.name }
            .merge(attributes.map { |k,a| [a.name, a.type.type] }.to_h)
            .as_json(options)
        end

        def inspect
          "#{name}(index: #{index_name}, document: #{document_type}, subject: #{subject_type}, #{attributes.map { |key,attr| "#{attr.name}: #{attr.nested? ? "[#{attr.type.type}]" : attr.type.type}"}.join(', ')})"
        end
      end

      module InstanceMethods
        delegate :index_name, :document_type, to: :class

        def as_indexed_json(options={})
          resolve!.as_json(options)
        end

        def index!(options={})
          raise Lycra::AbstractClassError, "Cannot index using an abstract class" if abstract?

          @indexed = nil
          __lycra__.index_document(options)
        end

        def update!(options={})
          raise Lycra::AbstractClassError, "Cannot update using an abstract class" if abstract?

          @indexed = nil
          __lycra__.update_document(options)
        end

        def update_attributes!(*attrs, **options)
          raise Lycra::AbstractClassError, "Cannot update using an abstract class" if abstract?

          if attrs.empty?
            document_attrs = resolve!
          else
            document_attrs = resolve!(only: attrs)
          end

          @indexed = nil
          __lycra__.update_document_attributes(document_attrs, options)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
          index!(options)
        end

        def _indexed
          @indexed ||= self.class.search({query: {terms: {_id: [subject.id]}}}).results.first
        end

        def indexed
          _indexed&._source&.to_h
        end

        def indexed?
          !!indexed
        end

        def _indexed?
          !!@indexed
        end

        def reload
          super if defined?(super)
          @indexed = nil
          self
        end

        def as_json(options={})
          resolve! unless resolved?

          { index: self.class.index_name,
            document: self.class.document_type,
            subject: self.class.subject_type.name,
            resolved: resolved.map { |k,a| [k, a.as_json] }.to_h,
            indexed: indexed? && indexed.map { |k,a| [k, a.as_json] }.to_h }
            .as_json(options)
        end

        def inspect
          attr_str = "#{attributes.map { |key,attr| "#{key}: #{(resolved? && resolved[key].try(:to_json)) || (_indexed? && indexed[key.to_s].try(:to_json)) || (attr.nested? ? "[#{attr.type.type}]" : attr.type.type)}"}.join(', ')}>"
          "#<#{self.class.name} index: #{self.class.index_name}, document: #{self.class.document_type}, subject: #{self.class.subject_type}, #{attr_str}"
        end
      end

      module BaseProxy
        attr_reader :target

        def initialize(target)
          @target = target
        end

        def client=(client)
          @client = client
        end

        def client
          @client ||= Lycra.client
        end

        def method_missing(meth, *args, &block)
          return target.send(meth, *args, &block) if target.respond_to?(meth)
          super
        end

        def respond_to_missing?(meth, priv=false)
          target.respond_to?(meth, priv) || super
        end
      end

      class ClassProxy
        include BaseProxy
        delegate :subject_type, :import_scope, to: :target

        # this is copying their (annoying) pattern
        class_eval do
          include ::Elasticsearch::Model::Indexing::ClassMethods
          include ::Elasticsearch::Model::Searching::ClassMethods
        end

        def alias_name(index_alias=nil)
          @_lycra_alias_name = index_alias if index_alias
          @_lycra_alias_name ||= document_type.pluralize
        end

        def alias_name=(index_alias)
          alias_name index_alias
        end

        def index_name(index=nil)
          @_lycra_index_name = index if index
          @_lycra_index_name ||= "#{alias_name}-#{Digest::MD5.hexdigest(mappings.to_s)}"
        end

        def index_name=(index)
          index_name index
        end

        def document_type(type=nil)
          @_lycra_document_type = type if type
          @_lycra_document_type ||= target.name.demodulize.gsub(/Document\Z/, '').underscore
        end

        def document_type=(type)
          document_type type
        end

        def mapping(mapping=nil)
          @_lycra_mapping = mapping if mapping
          { document_type.to_s.underscore.to_sym => (@_lycra_mapping || {}).merge({
              properties: attributes.map { |name, type| [name, type.mapping] }.to_h
          }) }
        end
        alias_method :mappings, :mapping

        def settings(settings=nil)
          @_lycra_settings = settings if settings
          @_lycra_settings || {}
        end

        def search(query_or_payload, options={})
          options = {index: alias_name}.merge(options)
          super(query_or_payload, options)
        end

        def alias_exists?
          client.indices.exists_alias? name: alias_name
        end

        def aliased_index
          client.indices.get_alias(name: alias_name).keys.first
        end

        def index_aliased?
          alias_exists? && aliased_index == index_name
        end

        def create_alias!(options={})
          # TODO custom error classes
          raise "Alias already exists" if alias_exists?
          client.indices.put_alias name: alias_name, index: index_name
        end

        def delete_alias!(options={})
          # TODO custom error classes
          raise "Alias does not exists" unless alias_exists?
          client.indices.delete_alias name: alias_name, index: aliased_index
        end
      end

      class InstanceProxy
        include BaseProxy
        delegate :index_name, :document_type, to: :klass_proxy
        delegate :subject_type, to: :klass

        # this is copying their (annoying) pattern
        class_eval do
          include ::Elasticsearch::Model::Indexing::InstanceMethods
        end

        def klass
          target.class
        end

        def klass_proxy
          klass.__lycra__
        end
      end
    end
  end
end
