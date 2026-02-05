require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<CUSTOMER_SERVICE_URL>') { ENV.fetch('CUSTOMER_SERVICE_URL', 'http://customer_service:3000') }
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri]
  }
  config.allow_http_connections_when_no_cassette = false
end
