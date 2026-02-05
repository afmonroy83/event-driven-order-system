# frozen_string_literal: true
require "bunny"
require "json"
require "logger"

class OrderCreatedConsumer
  EXCHANGE = "orders.events"
  QUEUE = "customer.order_created"
  @logger = Logger.new($stdout)

  def self.start
    loop do
      begin
        conn = Bunny.new(
          ENV.fetch("RABBITMQ_URL"),
          automatically_recover: true,
          network_recovery_interval: 5,
          heartbeat: 10
        )
        conn.start
        ch = conn.create_channel
        ch.prefetch(1)

        exchange = ch.topic(EXCHANGE, durable: true)
        queue = ch.queue(QUEUE, durable: true)
        queue.bind(exchange, routing_key: "order.created")

        @logger.info("Listening for order.created events...")

        queue.subscribe(block: true, manual_ack: true) do |delivery_info, _properties, body|
          begin
            payload = JSON.parse(body)
            handle(payload)
            ch.ack(delivery_info.delivery_tag)
          rescue JSON::ParserError => e
            @logger.error("Invalid JSON received: #{e.message}")
            ch.nack(delivery_info.delivery_tag, false, false) # descarta mensaje mal formado
          rescue StandardError => e
            @logger.error("Error handling message: #{e.message}")
            ch.nack(delivery_info.delivery_tag, false, true) # reintenta mensaje
          end
        end

      rescue Bunny::TCPConnectionFailed, Bunny::NetworkFailure => e
        @logger.warn("Lost connection to RabbitMQ: #{e.message}. Retrying in 5s...")
        sleep 5
        retry
      end
    end
  end

  def self.handle(payload)
    data = payload["data"]
    unless data
      @logger.warn("Message missing 'data' key, ignoring")
      return
    end

    customer = Customer.find_by(id: data["customer_id"])
    unless customer
      @logger.warn("Customer #{data['customer_id']} not found")
      return
    end

    customer.increment!(:orders_count)
    @logger.info("Incremented orders_count for Customer ##{customer.id}")
  end
end
