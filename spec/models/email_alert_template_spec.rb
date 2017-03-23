require "spec_helper"

RSpec.describe EmailAlertTemplate do
  include LockHandlerTestHelpers
  let(:content_id) { SecureRandom.uuid }
  let(:govuk_request_id) { SecureRandom.uuid }
  let(:public_updated_at) { updated_now.iso8601 }
  let(:document) do
    {
      "base_path" => "/foo",
      "content_id" => content_id,
      "title" => "Example title",
      "details" => {
        "tags" => {
          "browse_pages" => ["tax/vat"],
          "topics" => ["oil-and-gas/licensing"],
          "some_other_missing_tags" => [],
        }
      },
      "links" => {},
      "public_updated_at" => public_updated_at,
      "document_type" => "example_document",
      "publishing_app" => "Whitehall",
      "govuk_request_id" => govuk_request_id,
    }
  end
  let(:email_alert_template) { EmailAlertTemplate.new(document) }

  describe "#latest_change_note" do
    context "no change_history is present in the document" do
      it "returns nil" do
        expect(email_alert_template.send(:latest_change_note)).to be_nil
      end
    end

    context "change_history is present but empty" do
      before do
        document["details"]["change_history"] = []
      end

      it "returns nil" do
        expect(email_alert_template.send(:latest_change_note)).to be_nil
      end
    end

    context "change_history is present and populated" do
      before do
        document["details"]["change_history"] = [
          {
            "public_timestamp" => "2017-03-20T16:00:00.000+00:00",
            "note" => "updated again"
          },
          {
            "public_timestamp" => "2016-02-01T09:30:00.000+00:00",
            "note" => "First published."
          }
        ]
      end

      it "returns the latest change note" do
        expect(email_alert_template.send(:latest_change_note)).to eq("updated again")
      end
    end
  end
end
