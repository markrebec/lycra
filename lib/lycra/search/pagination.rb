module Lycra
  module Search
    module Pagination
      def self.included(base)
        base.send :delegate, :total_pages, :current_page, :limit_value, :offset_value, :last_page?, to: :response

        base.send :alias_method, :pages, :total_pages
      end

      def page(pg=nil)
        @response = response.page(pg || 1)
        self
      end

      def per(pr=nil)
        @response = response.per(pr || Lycra.configuration.per_page)
        self
      end

      def offset(ofst=nil)
        @response = response.offset(ofst || 0)
        self
      end

      def limit(lmt=nil)
        @response = response.limit(lmt || Lycra.configuration.per_page)
        self
      end

    end
  end
end
