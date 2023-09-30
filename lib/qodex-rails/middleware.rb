module QodexRails
  module Middleware
    class RequestLogger
      def initialize(app)
        @app = app
        @mutex = Mutex.new  # Mutex for thread-safe logging
      end

      def call(env)
        start_time = Time.now
        status, headers, response = @app.call(env)
        end_time = Time.now

        request = Rack::Request.new(env)
        filtered_params = request.filtered_parameters  # Uses Rails' parameter filtering

        @mutex.synchronize do  # Ensure thread-safe logging
          Rails.logger.info <<~LOG
            Request to #{request.path_info}
            Method: #{request.request_method}
            Parameters: #{filtered_params.inspect}
            Response Status: #{status}
            Time Taken: #{(end_time - start_time) * 1000} ms
          LOG
        end

        [status, headers, response]
      end
    end
  end
end
