require 'rails_helper'

RSpec.describe CustomerClient do
  subject(:client) { described_class.new }

  let(:customer_id) { 1 }
  let(:customer_response) do
    {
      'id' => customer_id,
      'name' => 'John Doe',
      'email' => 'john@example.com'
    }
  end

  describe '#find' do
    let(:mock_connection) { instance_double(Faraday::Connection) }
    let(:mock_response) { instance_double(Faraday::Response) }
    let(:circuit) { double('circuit') }

    before do
      allow(Faraday).to receive(:new).and_return(mock_connection)
      allow_any_instance_of(described_class).to receive(:circuit).and_return(circuit)
      allow(circuit).to receive(:run).and_yield
      allow(mock_connection).to receive(:get).and_return(mock_response)
      allow(mock_response).to receive(:success?).and_return(true)
      allow(mock_response).to receive(:body).and_return(customer_response.to_json)
    end

    it 'fetches customer from customer service' do
      result = client.find(customer_id)

      expect(mock_connection).to have_received(:get).with("/api/v1/customers/#{customer_id}")
    end

    it 'returns parsed customer data' do
      result = client.find(customer_id)

      expect(result['id']).to eq(customer_id)
      expect(result['name']).to eq('John Doe')
    end

    it 'uses circuit breaker pattern' do
      client.find(customer_id)

      expect(circuit).to have_received(:run)
    end

    it 'returns fallback when response is not successful' do
      allow(mock_response).to receive(:success?).and_return(false)
      allow(circuit).to receive(:run).and_yield
      allow(Rails.logger).to receive(:error)

      result = client.find(customer_id)

      expect(result['fallback']).to eq(true)
      expect(Rails.logger).to have_received(:error).with(/CustomerClient fallback triggered/)
    end

    it 'returns fallback when service times out' do
      allow(circuit).to receive(:run).and_raise(Faraday::TimeoutError)

      result = client.find(customer_id)

      expect(result['fallback']).to eq(true)
      expect(result['name']).to eq('Unknown customer')
      expect(result['id']).to eq(customer_id)
    end

    it 'returns fallback when connection fails' do
      allow(circuit).to receive(:run).and_raise(Faraday::ConnectionFailed)

      result = client.find(customer_id)

      expect(result['fallback']).to eq(true)
    end

    it 'returns fallback on any standard error' do
      allow(circuit).to receive(:run).and_raise(StandardError.new('Service unavailable'))

      result = client.find(customer_id)

      expect(result['fallback']).to eq(true)
    end

    it 'logs error when fallback is triggered' do
      allow(circuit).to receive(:run).and_raise(StandardError.new('Service error'))
      allow(Rails.logger).to receive(:error)

      client.find(customer_id)

      expect(Rails.logger).to have_received(:error).with(/CustomerClient fallback triggered/)
    end
  end

  describe 'fallback response' do
    it 'returns fallback with correct structure' do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .and_raise(Faraday::TimeoutError)

      result = client.find(123)

      expect(result).to eq({
        'id' => 123,
        'name' => 'Unknown customer',
        'fallback' => true
      })
    end
  end

  describe 'with VCR', :vcr do
    it 'records and replays HTTP interactions', vcr: { cassette_name: 'customer_client/find_customer', record: :once } do
      result = client.find(1)

      expect(result).to be_a(Hash)
      expect(result).to have_key('id')
      expect(result).to have_key('name')
    end
  end
end

  