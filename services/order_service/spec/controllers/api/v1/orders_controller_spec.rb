require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        order: {
          customer_id: 1,
          product_name: 'Product A',
          quantity: 2,
          price: 99.99,
          status: 'created'
        }
      }
    end

    let(:customer_response) do
      {
        'id' => 1,
        'name' => 'John Doe',
        'fallback' => false
      }
    end

    before do
      allow_any_instance_of(CustomerClient).to receive(:find).and_return(customer_response)
      allow(OrderCreatedPublisher).to receive(:publish)
    end

    it 'creates a new order' do
      expect {
        post :create, params: valid_params
      }.to change(Order, :count).by(1)
    end

    it 'returns created status' do
      post :create, params: valid_params

      expect(response).to have_http_status(:created)
    end

    it 'returns the created order as JSON' do
      post :create, params: valid_params

      json_response = JSON.parse(response.body)
      expect(json_response['customer_id']).to eq(1)
      expect(json_response['product_name']).to eq('Product A')
      expect(json_response['quantity']).to eq(2)
      expect(json_response['price']).to eq('99.99')
    end

    it 'calls CustomerClient to fetch customer information' do
      customer_client = instance_double(CustomerClient)
      allow(CustomerClient).to receive(:new).and_return(customer_client)
      allow(customer_client).to receive(:find).and_return(customer_response)

      post :create, params: valid_params

      expect(customer_client).to have_received(:find).with("1")
    end

    it 'publishes order created event' do
      post :create, params: valid_params

      order = Order.last
      expect(OrderCreatedPublisher).to have_received(:publish).with(order)
    end

    it 'sets customer_name from customer service response' do
      post :create, params: valid_params

      order = Order.last
      expect(order.customer_name).to eq('John Doe')
    end

    it 'sets status to pending when customer is fallback' do
      fallback_customer = {
        'id' => 1,
        'name' => 'Unknown customer',
        'fallback' => true
      }
      allow_any_instance_of(CustomerClient).to receive(:find).and_return(fallback_customer)

      post :create, params: valid_params

      order = Order.last
      expect(order.status).to eq('pending')
    end

    it 'sets status to created when customer is not fallback' do
      post :create, params: valid_params

      order = Order.last
      expect(order.status).to eq('created')
    end
  end

  describe 'GET #index' do
    let!(:order1) do
      Order.create!(
        customer_id: 1,
        customer_name: 'John Doe',
        product_name: 'Product A',
        quantity: 2,
        price: 99.99,
        status: 'created'
      )
    end

    let!(:order2) do
      Order.create!(
        customer_id: 2,
        customer_name: 'Jane Smith',
        product_name: 'Product B',
        quantity: 1,
        price: 49.99,
        status: 'pending'
      )
    end

    it 'returns orders filtered by customer_id' do
      get :index, params: { customer_id: 1 }

      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response.first['customer_id']).to eq(1)
    end

    it 'returns empty array when no orders match customer_id' do
      get :index, params: { customer_id: 999 }

      json_response = JSON.parse(response.body)
      expect(json_response).to eq([])
    end

  end
end
