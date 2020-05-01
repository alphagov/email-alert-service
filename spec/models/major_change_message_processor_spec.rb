require "spec_helper"

RSpec.describe MajorChangeMessageProcessor do
  let(:logger) { double(:logger, info: nil) }

  let(:message) {
    double(:message_queue_consumer_message, ack: nil, discard: nil,
                                            retry: nil, payload: good_document)
  }

  let(:bad_message) {
    double(:message_queue_consumer_message, ack: nil, discard: nil,
                                            retry: nil, payload: nil)
  }

  let(:processor) { MajorChangeMessageProcessor.new(logger) }
  let(:mock_email_alert) { double("EmailAlert", trigger: nil) }
  let(:change_history) do
    [
      {
        "note" => "First published.",
        "public_timestamp" => "2014-10-06T13:39:19.000+00:00",
      },
    ]
  end

  let(:good_document) do
    {
      "base_path" => "path/to-doc",
      "title" => "Example title",
      "document_type" => "example",
      "description" => "example description",
      "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
      "details" => {
        "change_history" => change_history,
        "tags" => {
          "topics" => ["example topic"],
        },
      },
      "links" => {
        "topics" => %w[example-topic-uuid],
      },
    }
  end

  def email_was_triggered
    expect(mock_email_alert).to have_received(:trigger)
  end

  def email_was_not_triggered
    expect(mock_email_alert).to_not have_received(:trigger)
  end

  def message_acknowledged
    expect(message).to have_received(:ack)
  end

  def message_rejected
    expect(message).to have_received(:discard)
  end

  def message_requeued
    expect(message).to have_received(:retry)
  end

  before do
    allow(EmailAlert).to receive(:new).and_return(mock_email_alert)
  end

  describe "#process" do
    it "acknowledges and triggers the email for a correctly tagged document" do
      processor.process(message)

      email_was_triggered
      message_acknowledged
    end

    context "document tagged with a policy" do
      before do
        good_document["details"]["tags"] = { "policies" => ["example policy"] }
        good_document["links"] = { "policies" => %w[example-policy-uuid] }
      end

      it "acknowledges and triggers the email" do
        processor.process(message)

        email_was_triggered
        message_acknowledged
      end
    end

    context "document with no details > tags key" do
      before do
        good_document["details"].delete("tags")
      end

      it "still acknowledges and triggers the email" do
        processor.process(message)

        email_was_triggered
        message_acknowledged
      end
    end

    context "document with no tags in its links hash" do
      before do
        good_document["links"].delete("topics")
      end

      it "still acknowledges and triggers the email" do
        processor.process(message)

        email_was_triggered
        message_acknowledged
      end
    end

    context "document with empty tags" do
      before do
        good_document["details"]["tags"] = { "topics" => [] }
        good_document["links"] = { "topics" => [] }
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document with missing tag fields" do
      before do
        good_document["links"].delete("topics")
        good_document["details"].delete("tags")
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "empty change note" do
      before do
        good_document["details"]["change_history"][0]["note"] = ""
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "missing change history" do
      before do
        good_document["details"]["change_history"] = nil
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "missing details hash" do
      before { good_document.delete("details") }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "missing links hash" do
      before { good_document.delete("links") }

      it "still acknowledges and triggers the email" do
        processor.process(message)

        email_was_triggered
        message_acknowledged
      end
    end

    context "no links or tags but of whitelisted document type" do
      before do
        good_document["details"] = { "change_history" => change_history }
        good_document["links"] = { "parent" => %w[parent-topic-uuid] }
        good_document["document_type"] = "service_manual_guide"
      end

      it "still acknowledges and triggers the email" do
        processor.process(message)

        email_was_triggered
        message_acknowledged
      end
    end

    context "has links but is from a blacklisted publishing application" do
      before do
        good_document["details"] = { "change_history" => change_history }
        good_document["links"] = { "taxons" => %w[taxon-uuid] }
        good_document["publishing_app"] = "travel-advice-publisher"
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "has links but is from a blacklisted document type" do
      before do
        good_document["details"] = { "change_history" => change_history }
        good_document["links"] = { "taxons" => %w[taxon-uuid] }
      end

      it "acknowledges but doesn't trigger the email for coming_soon document type" do
        good_document["document_type"] = "coming_soon"

        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end

      it "acknowledges but doesn't trigger the email for special_route document type" do
        good_document["document_type"] = "special_route"

        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "no links or tags but has a relevant document supertype" do
      before do
        good_document["details"] = { "change_history" => change_history }
        good_document["links"] = {}
        good_document["email_document_supertype"] = "announcements"
      end

      it "still acknowledges and triggers the email" do
        processor.process(message)

        email_was_triggered
        message_acknowledged
      end
    end

    context "no details hash, no links hash" do
      before do
        good_document.delete("links")
        good_document.delete("details")
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document raises an error" do
      it "rejects the document, doesn't trigger the email, and notifies an exception reporter" do
        expect(GovukError).to receive(:notify).with(StandardError)
        allow(bad_message).to receive(:payload).and_return(StandardError)

        processor.process(bad_message)

        email_was_not_triggered
        expect(bad_message).to have_received(:discard)
      end
    end

    context "email alert api returns an error" do
      before do
        allow(mock_email_alert).to receive(:trigger)
          .and_raise(GdsApi::HTTPBadGateway, 502, "Bad Request")
      end

      it "requeues the message and doesn't trigger an email" do
        processor.process(message)
        message_requeued
      end
    end

    context "document is not in English" do
      before { good_document["locale"] = "fr" }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has blank locale" do
      before { good_document["locale"] = nil }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has no base_path" do
      before { good_document.delete("base_path") }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has blank base_path" do
      before { good_document["base_path"] = nil }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has no title" do
      before { good_document.delete("title") }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has blank title" do
      before { good_document["title"] = nil }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has no public_updated_at" do
      before { good_document.delete("public_updated_at") }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has blank public_updated_at" do
      before { good_document["public_updated_at"] = nil }

      it "acknowledges but doesn't trigger the email" do
        processor.process(message)

        email_was_not_triggered
        message_acknowledged
      end
    end
  end
end
