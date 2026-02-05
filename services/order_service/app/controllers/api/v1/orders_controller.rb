module Api
    module V1
      class OrdersController < ApplicationController
        def create
          order = Orders::CreateOrder.call(order_params)
  
          render json: order, status: :created
        end
  
        def index
          orders = Order.where(customer_id: params[:customer_id])
          render json: orders
        end
  
        private
  
        def order_params
            params.require(:order).permit(
              :customer_id,
              :product_name,
              :quantity,
              :price,
              :status
            )
          end          
      end
    end
  end
  