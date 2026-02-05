module Customers
    class FindCustomer
      def self.call(id)
        Customer.find(id)
      end
    end
end
  