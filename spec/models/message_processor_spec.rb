require "spec_helper"
require "models/message_processor"

RSpec.describe MessageProcessor do
  let(:delivery_tag) { double(:delivery_tag) }
  let(:delivery_info) { double(:delivery_info, delivery_tag: delivery_tag) }
  let(:properties) { double(:properties, content_type: nil) }
  let(:channel) { double(:channel, acknowledge: nil, reject: nil) }
  let(:logger) { double(:logger, info: nil) }

  let(:processor) { MessageProcessor.new(channel, logger) }
  let(:mock_email_alert) { double("EmailAlert", trigger: nil) }

  let(:good_document) {
    {
      "base_path" => "path/to-doc",
      "title" => "Example title",
      "description" => "example description",
      "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
      "details" => {
        "tags" => {
          "topics" => ["example topic"]
        }
      },
      "links" => {
        "topics" => ["example-topic-uuid"]
      }
    }
  }

  def email_was_triggered
    expect(mock_email_alert).to have_received(:trigger)
  end

  def email_was_not_triggered
    expect(mock_email_alert).to_not have_received(:trigger)
  end

  def message_acknowledged
    expect(channel).to have_received(:acknowledge).with(delivery_tag, false)
  end

  def message_rejected
    expect(channel).to have_received(:reject).with(delivery_tag, false)
  end

  before do
    allow(EmailAlert).to receive(:new).and_return(mock_email_alert)
  end

  describe "#process" do
    it "acknowledges and triggers the email for a correctly tagged document" do
      processor.process(good_document.to_json, properties, delivery_info)

      email_was_triggered
      message_acknowledged
    end

    context "document tagged with a policy" do
      before do
        good_document["details"]["tags"] = { "policies" => ["example policy"] }
        good_document["links"] = { "policies" => ["example-policy-uuid"] }
      end

      it "acknowledges and triggers the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_triggered
        message_acknowledged
      end
    end

    context "document with no details > tags key" do
      before do
        good_document["details"].delete("tags")
      end

      it "still acknowledges and triggers the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_triggered
        message_acknowledged
      end
    end

    context "document with no tags in its links hash" do
      before do
        good_document["links"].delete("topics")
      end

      it "still acknowledges and triggers the email" do
        processor.process(good_document.to_json, properties, delivery_info)

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
        processor.process(good_document.to_json, properties, delivery_info)

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
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "missing details hash" do
      before { good_document.delete("details") }

      it "still acknowledges and triggers the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_triggered
        message_acknowledged
      end
    end

    context "missing links hash" do
      before { good_document.delete("links") }

      it "still acknowledges and triggers the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_triggered
        message_acknowledged
      end
    end

    context "no details hash, no links hash" do
      before { good_document.delete("links"); good_document.delete("details") }

      it "acknowledges but doesn't trigger the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document contains malformed JSON" do
      it "rejects the document, doesn't trigger the email, and notifies an exception reporter" do
        expect(Airbrake).to receive(:notify_or_ignore).with(MalformedDocumentError)

        processor.process("{]$£$*()}", properties, delivery_info)

        email_was_not_triggered
        message_rejected
      end
    end

    context "content type identifies the document as a heartbeat" do
      it "acknowledges but doesn't trigger the email" do
        properties = double(:properties, content_type: "application/x-heartbeat")

        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document is not in English" do
      before { good_document["locale"] = "fr" }

      it "acknowledges but doesn't trigger the email" do
        properties = double(:properties, content_type: "application/x-heartbeat")

        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has no title" do
      before { good_document.delete("title") }

      it "acknowledges but doesn't trigger the email" do
        properties = double(:properties, content_type: "application/x-heartbeat")

        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document has no public_updated_at" do
      before { good_document.delete("public_updated_at") }

      it "acknowledges but doesn't trigger the email" do
        properties = double(:properties, content_type: "application/x-heartbeat")

        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end
  end
end
