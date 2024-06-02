require "qodex-rails/version"
require "qodex-rails/masking_util"
require "qodex-rails/middleware"
require "qodex-rails/configuration"  # Require the new configuration file

module QodexRails
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    # Get or initialize the configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Allow block-style configuration
    def configure
      yield(configuration)
    end
  end

  class Railtie < Rails::Railtie
    initializer "qodex-rails.insert_middleware" do |app|
      app.config.middleware.use Middleware::RequestLogger
    end
  end
end
