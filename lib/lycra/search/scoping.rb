module Lycra
  module Search
    module Scoping
      def self.included(base)
        base.send :extend, ClassMethods
      end

      def aggregations
        @aggregations ||= Lycra::Search::Aggregations.new
      end

      def aggregate(agg=nil)
        aggregations << agg unless agg.nil?
        self
      end
      alias_method :aggregation, :aggregate

      def reaggregate(agg)
        @aggregations = Lycra::Search::Aggregations.new
        aggregate agg
      end

      def filters
        @filters ||= Lycra::Search::Filters.new
      end

      def filter(fltr=nil)
        filters << fltr unless fltr.nil?
        self
      end

      def refilter(fltr)
        @filters = Lycra::Search::Filters.new
        filter fltr
      end

      def query_filters
        query.filters
      end

      def query_filter(fltr=nil)
        query.filter fltr
        self
      end

      def requery_filter(fltr)
        query.refilter fltr
        self
      end

      def post_filters
        @post_filters ||= Lycra::Search::Filters.new
      end

      def post_filter(fltr=nil)
        post_filters << fltr unless fltr.nil?
        self
      end

      def repost_filter(fltr)
        @post_filters = Lycra::Search::Filters.new
        post_filter fltr
      end

      def sorter
        @sorter ||= Lycra::Search::Sort.new
      end

      def sort(srt=nil)
        sorter << srt unless srt.nil?
        self
      end

      def resort(srt=nil)
        @sorter = Lycra::Search::Sort.new
        sort srt
      end

      def filter_by(attr, vals)
        return self if vals.nil? || vals.empty?

        attr_filter = {
          bool: {
            must: [{
              or: vals.map { |val| {term: {attr.to_sym => val}} }
            }]
          }
        }

        filter(filter << attr_filter)

        self
      end

      def where(*args)
        args.extract_options!.each do |attr, vals|
          vals = [vals] unless vals.is_a?(Array)
          filter_by(attr, vals)
        end

        self
      end

      def find_by(*args)
        unfiltered.offset(0).limit(1).where(*args).first
      end

      def find(id)
        find_by(id: id).first
      end

      module ClassMethods
        def self.extended(base)
          # Generic Shared Scopes
          base.send :scope, :all, -> { offset(0).limit(10_000) }
          base.send :scope, :unfiltered, -> { refilter }
          base.send :scope, :unsorted, -> { resort }
          base.send :scope, :sort_by, -> (field, order=:asc) { sort({field => {order: order}}) }
          base.send :scope, :by_id, -> (*objs) {
            filter_by(:id, [objs].flatten.map { |obj| obj.respond_to?(:id) ? obj.id : obj })
          }
        end

        def scope(name, block)
          instance_eval do
            define_method name.to_sym do |*args|
              @response = nil
              instance_exec *args, &block
              self
            end
          end
        end
      end
    end
  end
end
