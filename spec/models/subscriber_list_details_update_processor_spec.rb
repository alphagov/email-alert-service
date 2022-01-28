require "spec_helper"

RSpec.describe SubscriberListDetailsUpdateProcessor do
  include MessageProcessorHelpers

  let(:logger) { double(:logger, info: nil) }

  let(:message) do
    double(
      :message_queue_consumer_message,
      ack: nil,
      discard: nil,
      retry: nil,
      payload: document,
    )
  end

  let(:processor) { SubscriberListDetailsUpdateProcessor.new(logger) }

  let(:content_id) { SecureRandom.uuid }

  let(:document_title) { "Example title" }
  let(:subscriber_list_title) { "An old outdated title" }
  let(:subscriber_list_slug) { "subscriber_list_slug" }

  let(:document) do
    {
      "base_path" => "path/to-doc",
      "content_id" => content_id,
      "title" => document_title,
      "locale" => "en",
    }
  end

  let(:subscriber_list_attributes) do
    {
      "content_id" => content_id,
      "slug" => subscriber_list_slug,
      "title" => subscriber_list_title,
    }
  end

  let(:updateable_parameters) { { "title" => document_title } }

  describe "#process" do
    it "acknowledges and triggers the update for a correctly formatted document" do
      stub_email_alert_api_has_subscriber_list(subscriber_list_attributes)
      stub_update_subscriber_list_details(slug: subscriber_list_slug, params: updateable_parameters)

      processor.process(message)

      message_acknowledged
      expect(logger).to have_received(:info).with(
        "triggering subscriber list update for document: #{document_title}",
      )
    end

    context "document is not in English" do
      let(:locale) { "fr" }
      before { document["locale"] = locale }

      it "acknowledges but doesn't trigger the update" do
        processor.process(message)

        message_acknowledged
        expect(logger).to have_received(:info).with(
          "not triggering subscriber list update for a non-english document #{document_title}: locale #{locale}",
        )
      end
    end

    context "document has no content_id" do
      before { document.delete("content_id") }

      it "acknowledges but doesn't trigger the update" do
        processor.process(message)

        message_acknowledged
        expect(logger).to have_received(:info).with(
          "not triggering subscriber list update for a document with no content_id: #{document}",
        )
      end
    end

    context "document has no title" do
      before { document.delete("title") }

      it "acknowledges but doesn't trigger the update" do
        processor.process(message)

        message_acknowledged
        expect(logger).to have_received(:info).with(
          "not triggering subscriber list update for a document with no title: #{document}",
        )
      end
    end
  end
end
