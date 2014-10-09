require "spec_helper"
require "config"
require "bunny"

RSpec.describe "Receiving major change notifications", type: :integration do
  let(:well_formed_document) {
    '{
        "base_path": "path/to-doc",
        "title": "Example title",
        "description": "example description",
        "public_updated_at": "2014-10-06T13:39:19.000+00:00",
        "details": {
          "change_note": "this doc has been changed",
          "tags": {
            "browse_pages": [],
            "topics": []
          }
        }
     }'
  }

  let(:malformed_json) { '{23o*&£}' }
  let(:malformed_document) { '{"houses": "are for living in"}' }

  before :each do
    Sidekiq::Worker.clear_all
    @message_processor, @channel = start_listener
  end

  after :each do
    stop_listener
    EmailAlertWorker.drain
  end

  it "discards invalid documents" do
    expect_any_instance_of(MessageProcessor).to receive(:discard).twice

    send_message(malformed_document)
    send_message(malformed_json)
    wait_for_messages_to_process
  end

  it "acknowledges the message for documents experiencing major changes" do
    allow_any_instance_of(EmailAlertWorker).to receive(:perform).and_return(email_alert_api_accepts_alert)
    expect_any_instance_of(MessageProcessor).to receive(:acknowledge).and_call_original

    send_message(well_formed_document, routing_key: "policy.major")
    wait_for_messages_to_process
  end

  it "doesn't process documents for other change types" do
    expect_any_instance_of(MessageProcessor).not_to receive(:process)

    send_message(well_formed_document, routing_key: "policy.minor")
    send_message(well_formed_document, routing_key: "policy.republish")
    wait_for_messages_to_process
  end

  it "sends an email alert for documents experiencing major changes" do
    allow_any_instance_of(EmailAlertWorker).to receive(:perform).and_return(email_alert_api_accepts_alert)
    expect_any_instance_of(EmailAlertWorker).to receive(:perform)

    send_message(well_formed_document, routing_key: "policy.major")
    wait_for_messages_to_process
    expect(EmailAlertWorker.jobs.size).to eq 1
  end
end
