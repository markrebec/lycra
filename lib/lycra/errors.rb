module Lycra
  class AttributeError < StandardError; end
  class MissingSubjectError < StandardError; end

  class DocumentNotFoundError < StandardError
    attr_reader :model

    def initialize(model=nil)
      @model = model

      if model.nil? || model.name.nil?
        msg = <<MSG
You must define a corresponding document class for all models utilizing Lycra::Model. For example, if your model is called BlogPost:

  # /app/documents/blog_post_document.rb
  class BlogPostDocument < Lycra::Document
    index_name 'blog-posts'
  end
MSG
      else
        msg = <<MSG
You must define a corresponding document class for your #{model.name} model. For example:

  # /app/documents/#{model.name.split('::').map { |n| n.underscore }.join('/')}_document.rb
  class #{model.name}Document < Lycra::Document
    index_name '#{model.name.parameterize.pluralize}'
  end
MSG
      end

      super(msg)
    end
  end

  class UndefinedIndexError < StandardError
    attr_reader :document

    def initialize(document=nil)
      @document = document

      if document.nil?
        super("You must define an index_name for your document class. Try: `index_name 'my-searchable-things'`")
      else
        super("You must define an index_name for your #{document.class.name}. Try: `index_name '#{subject_name.underscore.pluralize}'`")
      end
    end

    def subject_name
      if document.subject.is_a?(Class)
        document.subject.name
      else
        document.subject.class.name
      end
    end
  end
end
