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

      def pii_masking
        @pii_masking ||= QodexRails.configuration.pii_masking
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
        status, headers, response = @app.call(env)
        response_content_type = response.instance_eval('@response').headers['content-type']
        if response_content_type.present? && !(response_content_type.include?('application/json'))
          return [status, headers, response]
        end

        end_time = Time.now

        # Capture the response details
        response_body = extract_body(response)

        routes = Rails.application.routes
        parsed_route_info = routes.recognize_path(request.url, {method: request.request_method}) rescue nil
        return [status, headers, response] if parsed_route_info.blank?

        controller_name = parsed_route_info[:controller]
        action_name = parsed_route_info[:action]
        additional_info = parsed_route_info.except(:controller, :action)

        request_headers = extract_request_headers(env)
        response_headers = extract_headers(headers)
        request_params = request.params.merge(additional_info)

        request_headers = MaskingUtil.mask_data(request_headers, pii_masking)
        response_headers = MaskingUtil.mask_data(response_headers, pii_masking)
        request_params = MaskingUtil.mask_data(request_params, pii_masking)
        response_body = MaskingUtil.mask_data(response_body, pii_masking)
        request_url = MaskingUtil.mask_query_params(request.url, pii_masking)

        # Construct the logs
        logs = {
          collection_name: QodexRails.configuration.collection_name,
          api_key: QodexRails.configuration.api_key,
          api: {
            controller_name: controller_name,
            action_name: action_name,
            time_spent: (end_time - start_time).to_i,
            response_body: response_body,
            body_type: 'none-type',
            request_type: request.request_method,
            timestamp: Time.now.to_i,
            url: request_url,
            status: status,
            headers: request_headers,
            response_headers: response_headers,
            params: request_params  # Using Rails' parameter filtering
          }
        }

        # Send the logs to the external API
        send_to_api(logs) rescue nil

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
        api_host = QodexRails.configuration.api_host || 'https://api.app.qodex.ai'
        uri = URI("#{api_host}/api/v1/collections/create_sample_data/#{QodexRails.configuration.api_key}")
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
