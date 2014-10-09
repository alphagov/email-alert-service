require "spec_helper"

RSpec.describe EmailAlertWorker do
  describe "#perform(formatted_alert)" do
    it "sends the formatted alert to the email API client" do
      worker = EmailAlertWorker.new
      formatted_alert = double(:formatted_alert)
      email_api_client = double(:email_api_client)
      allow(GdsApi::EmailAlertApi).to receive(:new).and_return(email_api_client)

      expect(email_api_client).to receive(:send_alert).with(formatted_alert)

      worker.perform(formatted_alert)
    end
  end
end
