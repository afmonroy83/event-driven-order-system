require 'rails_helper'

RSpec.describe Orders::CreateOrder do
  describe '.call' do
    let(:params) do
      {
        customer_id: 1,
        product_name: 'Product A',
        quantity: 2,
        price: 99.99,
        status: 'created'
      }
    end

    let(:customer_response) do
      {
        'id' => 1,
        'name' => 'John Doe',
        'fallback' => false
      }
    end

    let(:customer_client) { instance_double(CustomerClient) }

    before do
      allow(CustomerClient).to receive(:new).and_return(customer_client)
      allow(customer_client).to receive(:find).and_return(customer_response)
      allow(OrderCreatedPublisher).to receive(:publish)
    end

    it 'creates an order' do
      expect {
        described_class.call(params)
      }.to change(Order, :count).by(1)
    end

    it 'returns the created order' do
      order = described_class.call(params)

      expect(order).to be_a(Order)
      expect(order).to be_persisted
    end

    it 'fetches customer information from CustomerClient' do
      described_class.call(params)

      expect(customer_client).to have_received(:find).with(1)
    end

    it 'sets customer_name from customer service response' do
      order = described_class.call(params)

      expect(order.customer_name).to eq('John Doe')
    end

    it 'sets status to created when customer is not fallback' do
      order = described_class.call(params)

      expect(order.status).to eq('created')
    end

    it 'sets status to pending when customer is fallback' do
      fallback_customer = {
        'id' => 1,
        'name' => 'Unknown customer',
        'fallback' => true
      }
      allow(customer_client).to receive(:find).and_return(fallback_customer)

      order = described_class.call(params)

      expect(order.status).to eq('pending')
    end

    it 'merges all order params with customer_name and status' do
      order = described_class.call(params)

      expect(order.customer_id).to eq(1)
      expect(order.product_name).to eq('Product A')
      expect(order.quantity).to eq(2)
      expect(order.price).to eq(99.99)
      expect(order.customer_name).to eq('John Doe')
      expect(order.status).to eq('created')
    end

    it 'publishes order created event' do
      order = described_class.call(params)

      expect(OrderCreatedPublisher).to have_received(:publish).with(order)
    end

    it 'raises error when order creation fails' do
      allow(Order).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      expect {
        described_class.call(params)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'handles customer service errors gracefully' do
      allow(customer_client).to receive(:find).and_raise(StandardError)

      expect {
        described_class.call(params)
      }.to raise_error(StandardError)
    end
  end
end
