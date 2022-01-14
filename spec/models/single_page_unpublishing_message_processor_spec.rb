require "spec_helper"

RSpec.describe SinglePageUnpublishingMessageProcessor do
  include MessageProcessorHelpers

  let(:logger)  { double(:logger, info: nil) }
  let(:message) do
    double(
      :message,
      ack: nil,
      discard: nil,
      retry: nil,
      payload: document,
    )
  end

  let(:processor) { SinglePageUnpublishingMessageProcessor.new(logger) }
  let(:mock_unpublishing_alert) { double("UnpublishingAlert", trigger: nil) }

  let(:content_id) { SecureRandom.uuid }
  let(:govuk_request_id) { SecureRandom.uuid }
  let(:public_updated_at) { Time.now.iso8601 }

  let(:published_in_error_payload) do
    {
      "document_type" => "gone",
      "schema_name" => "gone",
      "base_path" => "/foo",
      "locale" => "en",
      "publishing_app" => "whitehall",
      "public_updated_at" => public_updated_at,
      "details" => {
        "explanation" => "Why the page was published in error",
        "alternative_path" => alternative_path,
      },
      "content_id" => content_id,
      "govuk_request_id" => govuk_request_id,
      "payload_version" => 199,
    }
  end

  let(:consolidated_payload) do
    {
      "document_type" => "redirect",
      "schema_name" => "redirect",
      "base_path" => "/foo",
      "locale" => "en",
      "publishing_app" => "whitehall",
      "redirects" => [
        {
          "path" => "/government/publications/foo/html-attachment-foo",
          "type" => "exact",
          "destination" => "/government/publications/foobar",
        },
      ],
      "public_updated_at" => public_updated_at,
      "content_id" => content_id,
      "govuk_request_id" => govuk_request_id,
      "payload_version" => 199,
    }
  end

  def unpublish_alert_was_called
    expect(mock_unpublishing_alert).to have_received(:trigger)
  end

  def unpublish_alert_was_not_called
    expect(mock_unpublishing_alert).not_to have_received(:trigger)
  end

  before do
    allow(UnpublishingAlert).to receive(:new).with(document, logger, unpublishing_scenario).and_return(mock_unpublishing_alert)
  end

  describe "#process" do
    let(:unpublishing_scenario) { nil }

    shared_examples "a validated and acknowledged message" do
      it "acknowledges and triggers an email-api client call for a correctly tagged document" do
        processor.process(message)

        unpublish_alert_was_called
        message_acknowledged
      end

      context "a document without a base_path" do
        before { document.delete("base_path") }

        it "acknowledges but doesn't trigger the email" do
          processor.process(message)

          unpublish_alert_was_not_called
          message_acknowledged
        end
      end

      context "a document without a public_updated_at" do
        before { document.delete("public_updated_at") }

        it "acknowledges but doesn't trigger the email" do
          processor.process(message)

          unpublish_alert_was_not_called
          message_acknowledged
        end
      end

      context "a document without a content_id" do
        before { document.delete("content_id") }

        it "acknowledges but doesn't trigger the email" do
          processor.process(message)

          unpublish_alert_was_not_called
          message_acknowledged
        end
      end
    end

    describe "in an unknown unpublishing scenario" do
      let(:document) do
        {
          "document_type" => "woops",
          "schema_name" => "woops",
          "base_path" => "/foo",
          "public_updated_at" => public_updated_at,
          "content_id" => content_id,
        }
      end

      it "does not trigger an email-api client call and logs a message" do
        processor.process(message)

        unpublish_alert_was_not_called
        expect(logger).to have_received(:info).with(
          "not triggering bulk unsubscription and alert for document with a unknown unpublishing scenario. Document type: #{document['document_type']}",
        )
      end
    end

    describe "following published_in_error_with_url event" do
      let(:unpublishing_scenario) { :published_in_error_with_url }
      let(:alternative_path) { "/foo/alternative" }
      let(:document) { published_in_error_payload }

      it_behaves_like "a validated and acknowledged message"
    end

    describe "following consolidated event" do
      let(:unpublishing_scenario) { :consolidated }
      let(:document) { consolidated_payload }

      it_behaves_like "a validated and acknowledged message"
    end

    describe "following published_in_error_without_url event" do
      let(:unpublishing_scenario) { :published_in_error_without_url }
      let(:alternative_path) { "" }
      let(:document) { published_in_error_payload }

      it_behaves_like "a validated and acknowledged message"
    end
  end
end
