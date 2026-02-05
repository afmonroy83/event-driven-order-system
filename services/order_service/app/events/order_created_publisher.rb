# frozen_string_literal: true
require "bunny"
require "json"
require "logger"

class OrderCreatedPublisher
  @logger = Logger.new($stdout)
  @conn = nil
  @ch = nil
  @exchange = nil

  def self.setup
    return if @conn&.open?

    @conn = Bunny.new(
      ENV.fetch("RABBITMQ_URL"),
      automatically_recover: true,
      network_recovery_interval: 5,
      heartbeat: 10
    )
    @conn.start
    @ch = @conn.create_channel
    @exchange = @ch.topic("orders.events", durable: true)
    @logger.info("Publisher connected to RabbitMQ")
  rescue Bunny::TCPConnectionFailed => e
    @logger.error("Failed to connect to RabbitMQ: #{e.message}")
    sleep 5
    retry
  end

  def self.publish(order)
    setup

    payload = {
      event: "order.created",
      data: {
        order_id: order.id,
        customer_id: order.customer_id,
        quantity: order.quantity,
        price: order.price
      }
    }

    @exchange.publish(payload.to_json, routing_key: "order.created", persistent: true)
    @logger.info("Published order.created for Order ##{order.id}")
  rescue StandardError => e
    @logger.error("Error publishing message: #{e.message}")
  end

  def self.close
    @ch.close if @ch&.open?
    @conn.close if @conn&.open?
  end
end
