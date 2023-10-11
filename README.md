# Qodex::Rails

Qodex.ai leverages the power of AI to streamline and enhance your API testing processes. With its intuitive interface and intelligent capabilities, Qodex.ai allows developers and testers to automate their API testing workflows, ensuring robustness and reliability in deployed applications.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ # Gemfile

    gem 'qodex-rails'

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install qodex-rails

## Configuration
    # config/initializers/qodex_rails.rb

    
    QodexRails.configure do |config|
        # Your configuration settings for qodex-rails in the staging environment
        project_name = Rails.application.class.module_parent_name rescue 'qodex'
        config.collection_name = "#{project_name}-#{Rails.env}" # Name of the collection where logs will be stored
        config.enabled_in_production = false  # Set to true to enable in production
        config.api_key = 'Your API Key'
    end  
    
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/qodex-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/qodex-rails/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Qodex::Rails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/qodex-rails/blob/main/CODE_OF_CONDUCT.md).
