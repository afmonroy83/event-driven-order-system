module Api
    module V1
      class CustomersController < ApplicationController
        def show
          customer = Customers::FindCustomer.call(params[:id])
          render json: customer
        end
      end
    end
  end
  