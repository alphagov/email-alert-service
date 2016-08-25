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
        "change_note" => "this doc has been changed",
        "tags" => {
          "browse_pages" => [],
          "topics" => ["example topic"]
        }
      },
      "document_type" => "example_document"
    }.to_json
  }

  let(:malformed_json) { '{23o*&£}' }
  let(:invalid_document) { '{"houses": "are for living in"}' }

  around :each do |example|
    start_listener
    example.run
    stop_listener
  end

  it "discards malformed documents" do
    expect_any_instance_of(MessageProcessor).to receive(:discard).once.and_call_original
    expect_any_instance_of(GdsApi::EmailAlertApi).not_to receive(:send_alert)

    send_message(malformed_json)

    wait_for_messages_to_process
  end

  it "ignores invalid documents" do
    expect_any_instance_of(MessageProcessor).to receive(:acknowledge).once.and_call_original
    expect_any_instance_of(GdsApi::EmailAlertApi).not_to receive(:send_alert)

    send_message(invalid_document)

    wait_for_messages_to_process
  end

  it "acknowledges the message for documents experiencing major changes" do
    expect_any_instance_of(MessageProcessor).to receive(:acknowledge).and_call_original
    expect_any_instance_of(GdsApi::EmailAlertApi).to receive(:send_alert)

    send_message(well_formed_document, routing_key: "policy.major")

    wait_for_messages_to_process
  end

  it "doesn't process documents for other change types" do
    expect_any_instance_of(MessageProcessor).not_to receive(:process)
    expect_any_instance_of(GdsApi::EmailAlertApi).not_to receive(:send_alert)

    send_message(well_formed_document, routing_key: "policy.minor")
    send_message(well_formed_document, routing_key: "policy.republish")

    wait_for_messages_to_process
  end

  it "sends an email alert for documents experiencing major changes" do
    expect_any_instance_of(MessageProcessor).to receive(:acknowledge).and_call_original
    expect_any_instance_of(GdsApi::EmailAlertApi).to receive(:send_alert)

    send_message(well_formed_document, routing_key: "policy.major")

    wait_for_messages_to_process
  end
end

