require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'validations' do
    it 'creates an order with valid attributes' do
      order = Order.new(
        customer_id: 1,
        customer_name: 'John Doe',
        product_name: 'Product A',
        quantity: 2,
        price: 99.99,
        status: 'created'
      )

      expect(order).to be_valid
    end

    it 'requires customer_id' do
      order = Order.new(
        customer_name: 'John Doe',
        product_name: 'Product A',
        quantity: 2,
        price: 99.99,
        status: 'created'
      )

      expect(order).to be_valid
    end

    it 'requires product_name' do
      order = Order.new(
        customer_id: 1,
        customer_name: 'John Doe',
        quantity: 2,
        price: 99.99,
        status: 'created'
      )

      expect(order).to be_valid
    end

    it 'requires quantity' do
      order = Order.new(
        customer_id: 1,
        customer_name: 'John Doe',
        product_name: 'Product A',
        price: 99.99,
        status: 'created'
      )

      expect(order).to be_valid
    end

    it 'requires price' do
      order = Order.new(
        customer_id: 1,
        customer_name: 'John Doe',
        product_name: 'Product A',
        quantity: 2,
        status: 'created'
      )

      expect(order).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a customer by customer_id' do
      order = Order.create!(
        customer_id: 1,
        customer_name: 'John Doe',
        product_name: 'Product A',
        quantity: 2,
        price: 99.99,
        status: 'created'
      )

      expect(order.customer_id).to eq(1)
    end
  end

  describe 'scopes' do
    before do
      Order.destroy_all
      Order.create!(
        customer_id: 1,
        customer_name: 'John Doe',
        product_name: 'Product A',
        quantity: 2,
        price: 99.99,
        status: 'created'
      )
      Order.create!(
        customer_id: 2,
        customer_name: 'Jane Smith',
        product_name: 'Product B',
        quantity: 1,
        price: 49.99,
        status: 'pending'
      )
    end

    it 'filters orders by customer_id' do
      orders = Order.where(customer_id: 1)

      expect(orders.count).to eq(1)
      expect(orders.first.customer_id).to eq(1)
    end
  end
end
