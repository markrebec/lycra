module Lycra
  class Multidoc
    attr_reader :documents

    def initialize(*documents)
      @documents = documents.flatten
      @documents = Lycra::Document::Registry.all if @documents.empty?
    end

    def index_name
      documents.map { |d| d.index_name }
    end

    def document_type
      documents.map { |d| d.document_type }
    end

    def client
      Lycra.client
    end
  end
end
