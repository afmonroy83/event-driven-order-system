require "rails_helper"
require "ostruct"
require_relative "../../app/events/order_created_publisher"

RSpec.describe OrderCreatedPublisher do
  let(:order) do
    OpenStruct.new(
      id: 1,
      customer_id: 42,
      quantity: 2,
      price: 1000.0
    )
  end

  let(:mock_conn) { instance_double(Bunny::Session, start: true, open?: true, create_channel: mock_channel, close: true) }
  let(:mock_channel) { instance_double(Bunny::Channel, topic: mock_exchange, close: true, prefetch: true) }
  let(:mock_exchange) { instance_double(Bunny::Exchange, publish: true) }

  before do
    allow(Bunny).to receive(:new).and_return(mock_conn)
  end

  describe ".setup" do
    it "establishes a connection and channel with exchange" do
      OrderCreatedPublisher.setup

      expect(Bunny).to have_received(:new).with(
        ENV.fetch("RABBITMQ_URL"),
        automatically_recover: true,
        network_recovery_interval: 5,
        heartbeat: 10
      )
      expect(mock_conn).to have_received(:start)
      expect(mock_conn).to have_received(:create_channel)
      expect(mock_channel).to have_received(:topic).with("orders.events", durable: true)
    end

    it "does not recreate connection if already open" do
      OrderCreatedPublisher.instance_variable_set(:@conn, mock_conn)
      OrderCreatedPublisher.instance_variable_set(:@ch, mock_channel)
      OrderCreatedPublisher.instance_variable_set(:@exchange, mock_exchange)

      expect(Bunny).not_to receive(:new)
      OrderCreatedPublisher.setup
    end
  end

  describe ".publish" do
    it "publishes a message with correct payload and routing key" do
      OrderCreatedPublisher.publish(order)

      expected_payload = {
        event: "order.created",
        data: {
          order_id: order.id,
          customer_id: order.customer_id,
          quantity: order.quantity,
          price: order.price
        }
      }.to_json

      expect(mock_exchange).to have_received(:publish).with(
        expected_payload,
        routing_key: "order.created",
        persistent: true
      )
    end

    it "logs error when publishing fails" do
      allow(mock_exchange).to receive(:publish).and_raise(StandardError, "Boom")
      logger = double("Logger", info: nil, error: nil)
      stub_const("OrderCreatedPublisher::Logger", logger)

      expect { OrderCreatedPublisher.publish(order) }.not_to raise_error
    end
  end

  describe ".close" do
    before do 
        allow(mock_channel).to receive(:open?).and_return(true) 
    end
    
    it "closes channel and connection if open" do
      OrderCreatedPublisher.instance_variable_set(:@conn, mock_conn)
      OrderCreatedPublisher.instance_variable_set(:@ch, mock_channel)

      OrderCreatedPublisher.close

      expect(mock_channel).to have_received(:close)
      expect(mock_conn).to have_received(:close)
    end
  end
end
