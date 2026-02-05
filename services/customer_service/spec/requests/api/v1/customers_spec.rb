require "rails_helper"

RSpec.describe "Api::V1::Customers", type: :request do
  let!(:customer) { Customer.create!(name: "John Doe", address: "123 Main St", orders_count: 0) }
  let(:headers) { { "ACCEPT" => "application/json", "CONTENT_TYPE" => "application/json" } }

  describe "GET /api/v1/customers/:id" do
    it "returns the customer" do
      get "/api/v1/customers/#{customer.id}", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(customer.id)
    end

    it "returns 404 if customer not found" do
      get "/api/v1/customers/999999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
