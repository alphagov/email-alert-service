require "spec_helper"

RSpec.describe "Receiving major change notifications", type: :integration do
  include LockHandlerTestHelpers

  let(:well_formed_document) {
    {
      "base_path" => "path/to-doc",
      "title" => generate_title,
      "description" => "example description",
      "public_updated_at" => updated_now,
      "details" => {
        "change_history" => [
          {
            "note" => "First published.",
            "public_timestamp" => "2014-10-06T13:39:19.000+00:00"
          }
        ],
        "tags" => {
          "browse_pages" => [],
          "topics" => ["example topic"]
        }
      },
      "document_type" => "example_document"
    }.to_json
  }

  let(:malformed_json) { '{23o*&£}' }
  let(:document_missing_fields) { '{"houses": "are for living in"}' }
  let(:client) { double('client') }

  around :each do |example|
    start_listener
    example.run
    stop_listener
  end

  before :each do
    allow(Services).to receive(:email_api_client).and_return(client)
  end

  it "discards malformed documents" do
    expect_any_instance_of(MajorChangeMessageProcessor).to receive(:discard).once.and_call_original
    expect(client).not_to receive(:send_alert)

    send_message(malformed_json)

    wait_for_messages_to_process
  end

  it "ignores documents which are missing required fields" do
    expect_any_instance_of(MajorChangeMessageProcessor).to receive(:acknowledge).once.and_call_original
    expect(client).not_to receive(:send_alert)

    send_message(document_missing_fields)

    wait_for_messages_to_process
  end

  it "acknowledges the message for documents experiencing major changes" do
    expect_any_instance_of(MajorChangeMessageProcessor).to receive(:acknowledge).and_call_original
    expect(client).to receive(:send_alert)

    send_message(well_formed_document, routing_key: "policy.major")

    wait_for_messages_to_process
  end

  it "doesn't process documents for other change types" do
    expect_any_instance_of(MajorChangeMessageProcessor).not_to receive(:process)
    expect(client).to receive(:send_alert)

    send_message(well_formed_document, routing_key: "policy.minor")
    send_message(well_formed_document, routing_key: "policy.republish")

    wait_for_messages_to_process
  end

  it "sends an email alert for documents experiencing major changes" do
    expect_any_instance_of(MajorChangeMessageProcessor).to receive(:acknowledge).and_call_original
    expect(client).to receive(:send_alert)

    send_message(well_formed_document, routing_key: "policy.major")

    wait_for_messages_to_process
  end
end
