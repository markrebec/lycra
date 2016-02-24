module Lycra
  class Railtie < Rails::Railtie
    initializer "lycra.configure_rails_logger" do
      Lycra.configure do |config|
        config.logger = Rails.logger
      end
    end
  end
end
