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
      "links" => {},
      "public_updated_at" => updated_now.iso8601,
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
        "Received major change notification for #{document["title"]}, with topics #{document["details"]["tags"]["topics"]}"
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
      })
    end

    context "a parent link is present in the document" do
      before { document.merge!( { "links" => { "parent" => ["uuid-888"] } } ) }

      it "formats the message to include the parent link" do
        expect(email_alert.format_for_email_api).to eq({
          "subject" => "Example title",
          "body" => "This is an email.",
          "tags" => {
            "browse_pages"=>["tax/vat"],
            "topics"=>["oil-and-gas/licensing"]
          },
          "links" => {
            "parent" => ["uuid-888"]
          },
        })
      end
    end
  end
end
