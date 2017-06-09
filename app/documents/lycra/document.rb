require 'elasticsearch/persistence/model'

module Lycra
  # TODO explain how this is used, what it is, why, etc.

  # TODO add validations for the results of as_indexed_json against the mapped attributes

  class Document
    attr_reader :subject

    INDEX_REGEX = /\A#{::Lycra.configuration.index_prefix}-?/

    class << self
      def inherited(base)
        # Make sure we inherit the parent's class-level instance variables whenever we inherit from the class,
        # but clone the values in order to avoid modifying the parent class' attributes..
        base.send :instance_variable_set, :@lycra_index_name,    index_name.try(:dup)
        base.send :instance_variable_set, :@lycra_document_type, document_type.try(:dup)
        base.send :instance_variable_set, :@lycra_attributes,    attributes.try(:dup)
        base.send :instance_variable_set, :@lycra_mapping,       mapping.try(:dup)
        base.send :instance_variable_set, :@lycra_settings,      settings.try(:dup)
      end

      def document_type(doctype=nil)
        @lycra_document_type = doctype if doctype.present?
        @lycra_document_type
      end

      def index_name(zindex_name=nil)
        @lycra_index_name = prefixed_index_name(zindex_name) if zindex_name.present?
        @lycra_index_name
      end

      def attribute(name, type, mappings={})
        attributes[name] = {type: Elasticsearch::Persistence::Model::Utils.lookup_type(type)}.merge(mappings[:mapping] || {})
      end

      def attributes(attrs=nil)
        @lycra_attributes = attrs if attrs.present?
        @lycra_attributes ||= {}
      end

      def mapping(map=nil)
        @lycra_mapping = map if map.present?
        @lycra_mapping ||= {}
      end
      alias_method :mappings, :mapping

      def settings(settings=nil)
        @lycra_settings = settings if settings.present?
        @lycra_settings ||= {}
      end

      def prefixed_index_name(idx)
        [::Lycra.configuration.index_prefix, idx.to_s.gsub(INDEX_REGEX, '')].compact.join('-')
      end

      def index_basename
        index_name.to_s.gsub(INDEX_REGEX, '')
      end

      def import(*models, **opts, &block)
        models = [models].flatten
        document = models.first.lycra_document
        raise ArgumentError, 'All models must use the same index in order to be imported together' unless models.all? { |model| model.index_name == document.index_name }

        index_name = opts.delete(:index_name) || document.index_name

        if opts.delete(:force) == true && document.__elasticsearch__.client.indices.exists?(index: index_name)
          # delete the index if it exists and the force-create option was passed
          document.__elasticsearch__.client.indices.delete index: index_name
        end

        unless document.__elasticsearch__.client.indices.exists?(index: index_name)
          document.__elasticsearch__.client.indices.create index: index_name, update_all_types: true, body: {
            settings: document.settings,
            mappings: models.inject({}) { |mappings, model| mappings.merge!(model.mappings) } # hacky, need to map all the document mappings
          }
        end

        models.each do |model|
          model.index_name index_name
          model.import **opts, &block
          model.index_name document.index_name
        end
      end

      def rotate(*models, **opts, &block)
        models = [models].flatten
        document = models.first.lycra_document
        raise ArgumentError, 'All models must use the same index in order to be imported together' unless models.all? { |model| model.index_name == document.index_name }

        unstamped_alias = document.index_name
        timestamped_index = [unstamped_alias, Time.now.to_i].compact.join('-')
        existing_index = nil

        import(*models, **opts.merge({index_name: timestamped_index}), &block)

        if document.__elasticsearch__.client.indices.exists_alias? name: unstamped_alias
          existing_index = document.__elasticsearch__.client.indices.get_alias(name: unstamped_alias).keys.first
          document.__elasticsearch__.client.indices.delete_alias name: unstamped_alias, index: existing_index
        elsif document.__elasticsearch__.client.indices.exists? index: unstamped_alias
          document.__elasticsearch__.client.indices.delete index: unstamped_alias
        end
        document.__elasticsearch__.client.indices.put_alias name: unstamped_alias, index: timestamped_index
        document.__elasticsearch__.client.indices.delete index: existing_index unless existing_index.nil?
      end
    end

    # NOTE: HEADS UP! Yes, this is an INSTANCE METHOD!
    # It is a shortcut, since this class represents both your model **class** (i.e. MyModel) and your model **records** (i.e. MyModel.find(1)).
    #
    # normal class usage allows for things like:
    #
    # MyDocument.new(MyModel)          # interact with elasticsearch at the model level (index names, mappings, etc.)
    # MyDocument.new(MyModel.find(1))  # interact with elasticsearch at the record level (as_indexed_json, also has access to index name, etc.)
    #
    # but with this, we also get:
    #
    # document = MyDocument.new(MyModel)  # instantiate a class-level model document
    # # ... do some stuff at the class-level ...
    # document.new(my_model_record)        # easily re-use the same document class to decorate your record without needing to know what it was
    # # ... do some stuff with your record ...
    def new(object)
      self.class.new(object)
    end

    def initialize(subject)
      @subject = subject

      if subject.is_a?(Class)
        # TODO explain why and/or maybe add some ! methods that are more explicit about what we're doing
        unless self.class.index_name.present?
          raise Lycra::UndefinedIndexError, self
        end

        index_name(self.class.index_name)
        document_type(self.class.document_type)
        mapping(self.class.mapping)
        settings(self.class.settings)
      end
    end

    def document_type(doctype=nil)
      subject.__elasticsearch__.document_type doctype
    end

    def index_name(idx=nil)
      if idx.present?
        subject.__elasticsearch__.index_name self.class.prefixed_index_name(idx)
      else
        subject.__elasticsearch__.index_name
      end
    end

    def mapping(options={}, &block)
      self.class.attributes.each do |field, opts|
        subject.__elasticsearch__.mapping.indexes field, opts
      end

      if options.present? || block_given?
        subject.__elasticsearch__.mapping options, &block
      end

      subject.__elasticsearch__.mapping
    end
    alias_method :mappings, :mapping

    def settings(settings=nil, &block)
      subject.__elasticsearch__.settings settings, &block if settings.present? || block_given?
      subject.__elasticsearch__.settings
    end

    def method_missing(meth, *args, &block)
      return subject.send(meth, *args, &block) if respond_to_missing?(meth, true)
      super
    end

    def respond_to_missing?(meth, include_private=false)
      subject.respond_to?(meth, include_private)
    end

    def as_json(opts={})
      subject.as_json(opts)
    end

    def as_indexed_json(opts={})
      as_json(opts)
    end
  end
end
