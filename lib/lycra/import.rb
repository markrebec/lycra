module Lycra
  class Import
    attr_reader :documents

    def self.import(*args, **opts, &block)
      new(*args).import(**opts, &block)
    end

    def self.rotate(*args, **opts, &block)
      new(*args).import(**opts, &block)
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

    def import(batch_size: 200, &block)
      documents.each do |document|
        document.delete_alias! if document.alias_exists?
        document.delete_index! if document.index_exists?
        document.create_index!

        document.import batch_size: batch_size, &block
      end
    end

    def rotate(batch_size: 200, &block)
      documents.each do |document|
        document.create_index! unless document.index_exists?

        document.import batch_size: batch_size, &block

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
  end
end
