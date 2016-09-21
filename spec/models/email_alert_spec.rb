require "spec_helper"

RSpec.describe EmailAlert do
  include LockHandlerTestHelpers

  let(:document) do
    {
      "base_path" => "/foo",
      "title" => "Example title",
      "details" => {
        "tags" => {
          "browse_pages" => ["tax/vat"],
          "topics" => ["oil-and-gas/licensing"],
          "some_other_missing_tags" => [],
        }
      },
      "expanded_links" => {},
      "public_updated_at" => updated_now.iso8601,
      "document_type" => "example_document"
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
        "Received major change notification for #{document["title"]}, with details #{document["details"]}"
      )
    end

    it "sends an alert to the Email Alert API" do
      email_alert.trigger

      expect(alert_api).to have_received(:send_alert)
    end
  end

  describe "#format_for_email_api" do
    before do
      allow(EmailAlertTemplate).to receive(:new).and_return(
        double(:email_template, message_body: "This is an email.")
      )
    end

    it "formats the message to send to the email alert api" do
      expect(email_alert.format_for_email_api).to eq({
        "subject" => "Example title",
        "body" => "This is an email.",
        "tags" => {
          "browse_pages" => ["tax/vat"],
          "topics" => ["oil-and-gas/licensing"]
        },
        "links" => {},
        "document_type" => "example_document"
      })
    end

    context "a link is present in the document" do
      before do
        document.merge!(
          {
            "expanded_links" => {
              "topics" => [
                {
                  "analytics_identifier" => "12345",
                  "api_url" => "https://www.publishing.service.gov.uk/api/content/example/topic",
                  "base_path" => "/example/topic",
                  "content_id" => "uuid-888",
                  "description" => nil,
                  "document_type" => "example",
                  "locale" => "en",
                  "public_updated_at" => "2016-02-07T20:08:15Z",
                  "schema_name" => "example",
                  "title" => "Example linked content",
                  "web_url" => "https://www.gov.uk/example/topic",
                  "details" => {},
                  "links" => {}
                }
              ]
            }
          }
        )
      end

      it "includes a list of just the link content ids" do
        expect(email_alert.format_for_email_api).to eq({
          "subject" => "Example title",
          "body" => "This is an email.",
          "tags" => {
            "browse_pages"=>["tax/vat"],
            "topics"=>["oil-and-gas/licensing"]
          },
          "links" => {
            "topics" => ["uuid-888"]
          },
          "document_type" => "example_document"
        })
      end
    end

    context "blank tags are present" do
      before do
        document.merge!("expanded_links" => { "topics" => [] })
        document["details"]["tags"].merge!("topics" => [])
      end

      it "strips these out" do
        expect(email_alert.format_for_email_api).to eq({
          "subject" => "Example title",
          "body" => "This is an email.",
          "tags" => {
            "browse_pages"=>["tax/vat"],
          },
          "links" => {},
          "document_type" => "example_document"
        })
      end
    end
  end
end
