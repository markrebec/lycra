module Lycra
  module Search
    module Enumerable
      def self.included(base)
        base.send :delegate, :count, :size, :results, :records, :total_count, to: :response
        base.send :delegate, :first, to: :to_a

        base.send :alias_method, :total, :total_count
      end

      def result_type
        @result_type ||= :results
      end

      def as_results!
        @result_type = :results
        self
      end

      def as_records!
        @result_type = :records
        self
      end

      def as_results?
        @result_type != :records
      end

      def as_records?
        @result_type == :records
      end

      def decorate!
        @decorated = true
        self
      end
      alias_method :decorated!, :decorate!

      def undecorate!
        @decorated = false
        self
      end
      alias_method :undecorated!, :undecorate!

      def decorate?
        @decorated == true
      end

      def undecorate?
        @decorated != true
      end

      #### Enumeration ####

      def enumerable_method
        "#{'decorated_' if decorate?}#{result_type}".to_sym
      end

      def to_ary
        if decorate?
          send(enumerable_method)
        else
          send(enumerable_method).each do |result|
            apply_transformers(result)
          end.to_a
        end
      end
      alias_method :to_a, :to_ary

      def each(&block)
        if decorate?
          send("each_#{enumerable_method}", &block)
        else
          send(enumerable_method).each do |result|
            apply_transformers(result)
            yield(result) if block_given?
          end
        end
      end

      def map(&block)
        if decorate?
          send("map_#{enumerable_method}", &block)
        else
          send(enumerable_method).map do |result|
            apply_transformers(result)
            yield(result) if block_given?
          end
        end
      end

      #### Decoration & Transformations ####

      def transform(&block)
        (@transformers ||= []) << block
        self
      end

      def transformers
        @transformers ||= []
      end

      def apply_transformers(result)
        transformers.each do |transformer|
          transformer.call(result)
        end
      end

      def each_decorated_results(decorator=nil, &block)
        map_decorated_results(decorator, &block)
        @decorated_results
      end
      alias_method :decorated_results, :each_decorated_results
      alias_method :each_decorated_result, :each_decorated_results

      def map_decorated_results(decorator=nil, &block)
        mapped = []
        if @decorated_results
          mapped = @decorated_results.map(&block)
        else
          @decorated_results ||= results.map do |result|
            decorated = decorate_result(result, decorator)

            apply_transformers(decorated)
            mapped << (block_given? ? yield(decorated) : decorated)

            decorated
          end
        end
        mapped
      end

      def decorate_result(result, decorator=nil)
        if decorator
          decorator.decorate(result)
        else
          SearchDecorator.decorate(result)
        end
      end

      def each_decorated_records(decorator=nil, &block)
        map_decorated_records(decorator, &block)
        @decorated_records
      end
      alias_method :decorated_records, :each_decorated_records
      alias_method :each_decorated_record, :each_decorated_records

      def map_decorated_records(decorator=nil, &block)
        mapped = []
        if @decorated_records
          mapped = @decorated_records.map(&block)
        else
          @decorated_records ||= records.map do |record|
            decorated = decorate_record(record, decorator)

            apply_transformers(decorated)
            mapped << (block_given? ? yield(decorated) : decorated)

            decorated
          end
        end
        mapped
      end

      def decorate_record(record, decorator=nil)
        if decorator
          decorator.decorate(record)
        else
          record.decorate
        end
      end

      def records_with_hit(&block)
        @records_with_hit ||= records.map_with_hit do |record,hit|
          mash = Hashie::Mash.new(record: record, hit: hit)
          apply_transformers(mash)
          yield(mash) if block_given?
          mash
        end
      end

      def decorated_with_hit(decorator=nil, &block)
        @decorated_with_hit ||= records.map_with_hit do |record,hit|
          decorated = begin
            if decorator
              Hashie::Mash.new(record: decorator.decorate(record), hit: hit)
            else
              Hashie::Mash.new(record: record.decorate, hit: hit)
            end
          end

          apply_transformers(decorated)
          yield(decorated) if block_given?

          decorated
        end
      end
    end
  end
end
