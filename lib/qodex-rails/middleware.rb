require 'net/http'
require 'json'

module QodexRails
  module Middleware
    class RequestLogger
      def initialize(app)
        @app = app
        @mutex = Mutex.new  # Mutex for thread-safe logging
      end

      def call(env)
        # Exit early if collection_name or api_key are not configured
        unless QodexRails.configuration.collection_name && QodexRails.configuration.api_key
          Rails.logger.warn "QodexRails: collection_name or api_key not configured. Skipping middleware."
          return @app.call(env)
        end

        # Print the initializer keys to the output
        Rails.logger.info "QodexRails Initializer Keys: Collection Name: #{QodexRails.configuration.collection_name}, API Key: #{QodexRails.configuration.api_key}"

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
          apis: [{
            body: response_body,
            body_type: response.content_type,
            request_type: request.request_method,
            timestamp: Time.now.to_i,
            url: request.url,
            status: status,
            headers: extract_headers(headers),
            params: request.filtered_parameters  # Using Rails' parameter filtering
          }]
        }

        # Send the logs to the external API
        send_to_api(logs)

        [status, headers, response]
      end

      private

      def extract_body(response)
        body = ""
        response.each { |part| body << part }
        body
      end

      def extract_headers(headers)
        headers.map { |name, value| { name: name, value: value } }
      end

      def send_to_api(logs)
        uri = URI("https://api.app.qodex.ai/api/v1/collections/create_with_folder/#{QodexRails.configuration.api_key}")
        request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        request.body = JSON.generate(logs)
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        # Optionally log the response from the external API
        Rails.logger.info "URI: #{uri}, API Response: #{response.body}" if response
      end
    end
  end
end
