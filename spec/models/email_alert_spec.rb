require "spec_helper"

RSpec.describe EmailAlert do
  include LockHandlerTestHelpers
  let(:content_id) { SecureRandom.uuid }
  let(:govuk_request_id) { SecureRandom.uuid }
  let(:public_updated_at) { updated_now.iso8601 }
  let(:document) do
    {
      "base_path" => "/foo",
      "content_id" => content_id,
      "title" => "Example title",
      "description" => "Example description",
      "details" => {
        "tags" => {
          "browse_pages" => ["tax/vat"],
          "topics" => ["oil-and-gas/licensing"],
          "some_other_missing_tags" => [],
        },
        "change_history" => [
          {
            "public_timestamp": "2017-10-19T16:09:23.000+01:00",
            "note" => "latest change note"
          },
          {
            "public_timestamp": "2017-10-16T12:09:00.000+01:00",
            "note" => "old change note"
          }
        ]
      },
      "links" => {},
      "public_updated_at" => public_updated_at,
      "document_type" => "example_document",
      "email_document_supertype" => "publications",
      "government_document_supertype" => "example_supertype",
      "publishing_app" => "Whitehall",
      "govuk_request_id" => govuk_request_id,
    }
  end

  class FakeLockHandler
    def with_lock_unless_done
      yield
    end
  end

  let(:logger) { double(:logger, info: nil) }
  let(:alert_api) { double(:alert_api, send_alert: nil) }
  let(:email_alert) { EmailAlert.new(document, logger) }
  let(:fake_lock_handler) { FakeLockHandler.new }

  before do
    allow(GdsApi::EmailAlertApi).to receive(:new).and_return(alert_api)
    allow(LockHandler).to receive(:new).and_return(fake_lock_handler)
  end

  describe "#trigger" do
    it "logs receiving a major change notification for a document" do
      email_alert.trigger

      expect(logger).to have_received(:info).with(
        "Received major change notification for #{document['title']}, with details #{document['details']}"
      )
    end

    it "sends an alert to the Email Alert API" do
      email_alert.trigger

      expect(alert_api).to have_received(:send_alert).with(
        hash_including("content_id" => content_id),
        govuk_request_id: govuk_request_id
      )
    end

    it "logs if it receives a conflict" do
      allow(alert_api).to receive(:send_alert).and_raise(GdsApi::HTTPConflict.new(409))
      email_alert.trigger

      expect(logger).to have_received(:info).with(
        "email-alert-api returned conflict for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
      )
    end
  end

  describe "#format_for_email_api" do
    before do
      allow(EmailAlertTemplate).to receive(:new).and_return(
        double(:email_template, message_body: "This is an email.")
      )
    end

    it "formats the message to send to the email alert api" do
      expect(email_alert.format_for_email_api).to eq(
        "subject" => "Example title",
        "body" => "This is an email.",
        "content_id" => content_id,
        "public_updated_at" => public_updated_at,
        "publishing_app" => "Whitehall",
        "tags" => {
          "browse_pages" => ["tax/vat"],
          "topics" => ["oil-and-gas/licensing"]
        },
        "links" => {},
        "document_type" => "example_document",
        "email_document_supertype" => "publications",
        "government_document_supertype" => "example_supertype",
        "base_path" => "/foo",
        "title" => "Example title",
        "description" => "Example description",
        "change_note" => "latest change note",
        "priority" => "normal",
      )
    end

    context "a link is present in the document" do
      before { document.merge!("links" => { "topics" => ["uuid-888"] }) }

      it "formats the message to include the parent link" do
        expect(email_alert.format_for_email_api).to include(
          "links" => {
            "topics" => ["uuid-888"]
          }
        )
      end
    end

    context "blank tags are present" do
      before do
        document["links"] = { "topics" => [] }
        document["details"]["tags"].merge!("topics" => [])
      end

      it "strips these out" do
        expect(email_alert.format_for_email_api["tags"]).not_to include("topics")
      end
    end

    context 'taxon links are present' do
      before do
        document.merge!(
          "links" => { "taxons" => %w(uuid-1 uuid-3) },
          "expanded_links" => {
            "taxons" => [
              {
                "content_id" => "uuid-1",
                "links" => {
                  "parent_taxons" => [
                    { "content_id" => "uuid-2", "links" => {} },
                  ]
                }
              },
              {
                "content_id" => "uuid-3",
                "links" => {
                  "parent_taxons" => [
                    { "content_id" => "uuid-2", "links" => {} },
                  ]
                }
              }
            ]
          }
        )
      end

      it 'adds the linked taxon and a unique list of its ancestors to the message' do
        links_hash = email_alert.format_for_email_api["links"]

        expect(links_hash["taxons"]).to eq %w(uuid-1 uuid-3)
        expect(links_hash["taxon_tree"].sort).to eq %w(uuid-1 uuid-2 uuid-3)
      end
    end

    context "with a travel advice" do
      before do
        document.merge!("document_type" => "travel_advice")
      end

      it "should be high priority" do
        expect(email_alert.format_for_email_api["priority"]).to eq("high")
      end

      it "should have a blank description" do
        expect(email_alert.format_for_email_api["description"]).to eq("")
      end
    end

    context "with a medical safety alert" do
      before do
        document.merge!("document_type" => "medical_safety_alert")
      end

      it "should be high priority" do
        expect(email_alert.format_for_email_api["priority"]).to eq("high")
      end
    end
  end
end
