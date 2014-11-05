require "spec_helper"

RSpec.describe EmailAlertWorker do
  before :each do
    allow(Redis).to receive(:new).and_return(mock_redis)
    allow(GdsApi::EmailAlertApi).to receive(:new).and_return(email_api_client)
  end

  let(:worker) { EmailAlertWorker.new }
  let(:email_api_client) { double(:email_api_client) }

  describe "#perform(email_data)" do
    it "sends the formatted email to the email API client" do
      expect(email_api_client).to receive(:send_alert).with(email_data["formatted"])

      worker.perform(email_data)
    end
  end

  it "sets a lock key for the formatted email sent" do
    aproximate_expiry_period_in_seconds = 770000

    allow_any_instance_of(LockHandler).to receive(:validate_and_set_lock).and_call_original
    expect(email_api_client).to receive(:send_alert).with(email_data["formatted"])

    worker.perform(email_data)

    expect(
      mock_redis.ttl(
        lock_key_for_email_data
      )
    ).to be > aproximate_expiry_period_in_seconds
  end

  it "does not send an email if there is an existing lock key" do
    email_data_with_set_time = {
      "formatted" => { "subject" => "Example Alert" },
      "public_updated_at" => updated_now
    }

    expect(email_api_client).to receive(:send_alert).with(email_data_with_set_time["formatted"]).exactly(:once)

    2.times do
      worker.perform(email_data_with_set_time)
    end
  end

  it "does not set a lock key if the formatted email was updated outside the valid expiry period" do
    allow_any_instance_of(LockHandler).to receive(:set_lock_with_expiry).and_call_original
    expect(email_api_client).not_to receive(:send_alert).with(expired_email_data)

    worker.perform(expired_email_data)
  end
end
