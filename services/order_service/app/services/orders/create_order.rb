module Orders
    class CreateOrder
      def self.call(params)
        new(params).call
      end
  
      def initialize(params)
        @params = params
      end
  
      def call
        customer = CustomerClient.new.find(@params[:customer_id])
  
        order = Order.create!(
          @params.merge(
            customer_name: customer["name"],
            status: fallback?(customer) ? "pending" : "created"
          )
        )
  
        OrderCreatedPublisher.publish(order)
  
        order
      end
  
      private
  
      def fallback?(customer)
        customer["fallback"] == true
      end
    end
end
  