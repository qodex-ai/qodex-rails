require "qodex-rails/version"
require "qodex-rails/middleware"

module QodexRails
  class Error < StandardError; end

  class Railtie < Rails::Railtie
    initializer "qodex-rails.insert_middleware" do |app|
      app.config.middleware.use Middleware::RequestLogger
    end
  end
end
