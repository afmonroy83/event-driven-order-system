RSpec.configure do |config|
  config.before(:each) do |example|
    OrderCreatedPublisher.instance_variable_set(:@conn, nil)
    OrderCreatedPublisher.instance_variable_set(:@ch, nil)
    OrderCreatedPublisher.instance_variable_set(:@exchange, nil)
    
    example_group = example.example_group
    is_publisher_test = example_group.respond_to?(:described_class) && 
                        example_group.described_class == OrderCreatedPublisher
    
    unless is_publisher_test
      allow(OrderCreatedPublisher).to receive(:publish).and_return(true)
      allow(OrderCreatedPublisher).to receive(:setup).and_return(true)
      allow(OrderCreatedPublisher).to receive(:close).and_return(true)
    else
      mock_connection = instance_double(Bunny::Session)
      mock_channel = instance_double(Bunny::Channel)
      mock_exchange = instance_double(Bunny::Exchange)
      
      allow(Bunny).to receive(:new).and_return(mock_connection)
      allow(mock_connection).to receive(:start)
      allow(mock_connection).to receive(:open?).and_return(false)
      allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
      allow(mock_channel).to receive(:topic).and_return(mock_exchange)
      allow(mock_exchange).to receive(:publish)
      allow(mock_channel).to receive(:open?).and_return(true)
      allow(mock_connection).to receive(:close)
      allow(mock_channel).to receive(:close)
    end
  end
end
