module Lycra
  class Engine < ::Rails::Engine
    isolate_namespace Lycra

    initializer "lycra.configure_rails_logger" do
      Lycra.configure do |config|
        config.logger = Rails.logger
      end
    end
  end
end
