require 'net/http'
require 'json'

module QodexRails
  module Middleware
    class RequestLogger
      def initialize(app)
        @app = app
        @mutex = Mutex.new  # Mutex for thread-safe logging
        @allowed_environments = QodexRails.configuration.allowed_environments || ['staging']
        @frequency = QodexRails.configuration.frequency || 'low'
      end

      def call(env)
        
        # Check if the current environment is allowed
        return @app.call(env) unless @allowed_environments.include?(Rails.env)

        # Exit early if collection_name or api_key are not configured
        unless QodexRails.configuration.collection_name && QodexRails.configuration.api_key
          Rails.logger.warn "QodexRails: collection_name or api_key not configured. Skipping middleware."
          return @app.call(env)
        end

        # Decide whether to log based on frequency setting
        random_number = rand(20) + 1
        case @frequency
        when 'low'
          return @app.call(env) unless random_number == 1
        when 'medium'
          return @app.call(env) unless random_number <= 4
        end

        # Print the initializer keys to the output
        # Rails.logger.info "QodexRails Initializer Keys: Collection Name: #{QodexRails.configuration.collection_name}, API Key: #{QodexRails.configuration.api_key}"

        start_time = Time.now
        
        # Capture the request details
        request = Rack::Request.new(env)
        request_body = request.body.read
        request.body.rewind
        
        status, headers, response = @app.call(env)
        
        end_time = Time.now

        # Capture the response details
        response_body = extract_body(response)
        
        # Construct the logs
        logs = {
          collection_name: QodexRails.configuration.collection_name,
          api_key: QodexRails.configuration.api_key,
          api: {
            time_spent: (end_time - start_time).to_i,
            body: request_body,
            response_body: response_body,
            body_type: 'none-type',
            request_type: request.request_method,
            timestamp: Time.now.to_i,
            url: request.url,
            status: status,
            headers: extract_request_headers(env),
            response_headers: extract_headers(headers),
            params: request.params  # Using Rails' parameter filtering
          }
        }

        # Send the logs to the external API
        send_to_api(logs)

        [status, headers, response]
      end

      private

      def extract_request_headers(env)
        env.select { |k, v| k.start_with?('HTTP_') }
        .map { |pair| [pair[0].sub(/^HTTP_/, ''), pair[1]] }
        .map { |pair| [pair[0].split('_').collect(&:capitalize).join('-'), pair[1]] }
        .to_h
      end

      def extract_body(response)
        body = ""
        response.each { |part| body << part } if response.respond_to?(:each)
        body
      end

      def extract_headers(headers)
        headers.to_h if headers.respond_to?(:map)
      end

      def send_to_api(logs)
        uri = URI("https://api.app.qodex.ai/api/v1/collections/create_sample_data/#{QodexRails.configuration.api_key}")
        request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        request.body = JSON.generate(logs)
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        # Optionally log the response from the external API
        # Rails.logger.info "URI: #{uri}, API Response: #{response.body}" if response
      end
    end
  end
end
