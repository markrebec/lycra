module Lycra
  class Multimodel
    attr_reader :models

    # @param models [Class] The list of models across which the search will be performed
    #
    def initialize(*models)
      @models = models.flatten
      #@models = Model::Registry.all if @models.empty?
    end

    # Get an Array of index names used for retrieving documents when doing a search across multiple models
    #
    # @return [Array] the list of index names used for retrieving documents
    #
    def index_name
      models.map { |m| m.index_name }
    end

    # Get an Array of document types used for retrieving documents when doing a search across multiple models
    #
    # @return [Array] the list of document types used for retrieving documents
    #
    def document_type
      models.map { |m| m.document_type }
    end

    # Get the client common for all models
    #
    # @return Elasticsearch::Transport::Client
    #
    def client
      Lycra.client
    end
  end
end
