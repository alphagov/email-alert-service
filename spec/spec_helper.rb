ENV["GOVUK_ENV"] = "test"
ENV["GOVUK_APP_DOMAIN"] = "test.gov.uk"

require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  minimum_coverage line: 90
end

require "webmock/rspec"

require_relative "../email_alert_service/environment"
require "gds_api/test_helpers/email_alert_api"

Dir[File.join(EmailAlertService.config.app_root, "spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.expose_dsl_globally = false
  config.order = :random

  config.include(GdsApi::TestHelpers::EmailAlertApi)
end

WebMock.disable_net_connect!
