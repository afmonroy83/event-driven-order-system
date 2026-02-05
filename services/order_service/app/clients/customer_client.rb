class CustomerClient
    BASE_URL = ENV.fetch("CUSTOMER_SERVICE_URL", "http://customer_service:3000")
  
    TIMEOUT = 2
    OPEN_TIMEOUT = 1
  
    def initialize
      @connection = Faraday.new(url: BASE_URL) do |f|
        f.request :retry,
          max: 3,
          interval: 0.05,
          interval_randomness: 0.5,
          backoff_factor: 2,
          exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
  
        f.options.timeout = TIMEOUT
        f.options.open_timeout = OPEN_TIMEOUT
  
        f.adapter Faraday.default_adapter
      end
    end
  
    def find(customer_id)
      circuit.run do
        response = @connection.get("/api/v1/customers/#{customer_id}")
  
        raise "Customer service error" unless response.success?
  
        JSON.parse(response.body)
      end
    rescue StandardError => e
      Rails.logger.error("CustomerClient fallback triggered: #{e.message}")
      fallback(customer_id)
    end
  
    private
  
    def circuit
      @circuit ||= Circuitbox.circuit(
        :customer_service,
        exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed, RuntimeError],
        sleep_window: 10,
        time_window: 60,
        volume_threshold: 5,
        error_threshold: 50
      )
    end
  
    def fallback(customer_id)
      {
        "id" => customer_id,
        "name" => "Unknown customer",
        "fallback" => true
      }
    end
end
  