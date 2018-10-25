module Lycra
  class Import
    attr_reader :documents

    def self.create(*args, &block)
      new(*args).create(&block)
    end

    def self.recreate(*args, &block)
      new(*args).recreate(&block)
    end

    def self.destroy(*args, &block)
      new(*args).destroy(&block)
    end

    def self.import(*args, **opts, &block)
      new(*args).import(**opts, &block)
    end

    def self.rotate(*args, **opts, &block)
      new(*args).rotate(**opts, &block)
    end

    def self.reindex(*args, **opts, &block)
      new(*args).reindex(**opts, &block)
    end

    def self.delete(*args, **opts, &block)
      new(*args).delete(**opts, &block)
    end

    def initialize(*documents)
      @documents = documents
      @documents = Lycra::Document::Registry.all if @documents.empty?
    end

    def total
      documents.sum do |doc|
        if doc.import_scope.is_a?(Proc)
          doc.subject_type.instance_exec(&doc.import_scope).count
        elsif doc.import_scope.is_a?(String) || doc.import_scope.is_a?(Symbol)
          doc.subject_type.send(doc.import_scope).count
        else
          doc.all.count
        end
      end
    end

    def create(&block)
      documents.each do |document|
        document.create_index! unless document.index_exists?
        yield(document) if block_given?
      end
    end

    def recreate(&block)
      documents.each do |document|
        document.delete_alias! if document.alias_exists?
        document.delete_index! if document.index_exists?
        document.create_index!
        yield(document) if block_given?
      end
    end

    def destroy(&block)
      documents.each do |document|
        document.delete_alias! if document.alias_exists?
        document.delete_index! if document.index_exists?
        yield(document) if block_given?
      end
    end

    def import(batch_size: 200, scope: nil, query: nil, &block)
      documents.each do |document|
        document.delete_alias! if document.alias_exists?
        document.delete_index! if document.index_exists?
        document.create_index!

        document.import! batch_size: batch_size, scope: scope, query: query, &block
      end
    end

    def rotate(batch_size: 200, scope: nil, query: nil, &block)
      documents.each do |document|
        document.create_index! unless document.index_exists?

        document.update! batch_size: batch_size, scope: scope, query: query, &block

        unless document.index_aliased?
          if document.alias_exists?
            old_index = document.aliased_index
            document.delete_alias!
            document.delete_index!(index: old_index)
          end

          document.create_alias!
        end
      end
    end

    def reindex(batch_size: 200, scope: nil, query: nil, &block)
      documents.each do |document|
        document.update! batch_size: batch_size, scope: scope, query: query, &block
      end
    end

    def delete(batch_size: 200, scope: nil, query: nil, &block)
      documents.each do |document|
        document.delete! batch_size: batch_size, scope: scope, query: query, &block
      end
    end
  end
end
