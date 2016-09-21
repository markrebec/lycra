module Lycra
  class Engine < ::Rails::Engine
    isolate_namespace Lycra

    initializer "lycra.configure_rails_logger" do
      Lycra.configure do |config|
        config.logger = Rails.logger if config.logger.nil?
      end
    end

    initializer "lycra.elasticsearch.client" do |app|
      Elasticsearch::Model.client = Lycra.client
      Elasticsearch::Persistence.client = Lycra.client
    end
  end
end
