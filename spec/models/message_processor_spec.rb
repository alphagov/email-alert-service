require "spec_helper"
require "models/message_processor"

RSpec.describe MessageProcessor do
  let(:delivery_tag) { double(:delivery_tag) }
  let(:delivery_info) { double(:delivery_info, delivery_tag: delivery_tag) }
  let(:channel) {
    double(:channel,
      acknowledge: nil,
      reject: nil
    )
  }
  let(:logger) { double(:logger, info: nil) }
  let(:processor) { MessageProcessor.new(channel, logger) }

  let(:not_tagged_document) {
    '{
        "base_path": "path/to-doc",
        "title": "Example title",
        "description": "example description",
        "public_updated_at": "2014-10-06T13:39:19.000+00:00",
        "details": {
          "change_note": "this doc has been changed",
          "tags": {
            "browse_pages": [],
            "topics": []
          }
        }
     }'
  }

  let(:document_with_no_tags_key) {
    '{
        "base_path": "path/to-doc",
        "title": "Example title",
        "description": "example description",
        "public_updated_at": "2014-10-06T13:39:19.000+00:00",
        "details": {
          "change_note": "this doc has been changed"
        }
     }'
  }

  let(:document_with_no_topics_key) {
    '{
        "base_path": "path/to-doc",
        "title": "Example title",
        "description": "example description",
        "public_updated_at": "2014-10-06T13:39:19.000+00:00",
        "details": {
          "change_note": "this doc has been changed",
          "tags": {
            "browse_pages": []
          }
        }
     }'
  }

  let(:tagged_document) {
    '{
        "base_path": "path/to-doc",
        "title": "Example title",
        "description": "example description",
        "public_updated_at": "2014-10-06T13:39:19.000+00:00",
        "details": {
          "change_note": "this doc has been changed",
          "tags": {
            "browse_pages": [],
            "topics": ["example topic one", "example topic two"]
          }
        }
      }'
    }

  describe "#process(document_json, delivery_info)" do
    it "acknowledges and triggers the message if the document has topics" do
      expect(processor).to receive(:trigger_email_alert)
      processor.process(tagged_document, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "acknowledges but doesnt trigger the message if the document is not tagged to a topic" do
      expect(processor).to_not receive(:trigger_email_alert)
      processor.process(not_tagged_document, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "acknowledges but doesnt trigger the message if the document does not have a tags key" do
      expect(processor).to_not receive(:trigger_email_alert)
      processor.process(document_with_no_tags_key, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "acknowledges but doesnt trigger the message if the document does not have a topics key" do
      expect(processor).to_not receive(:trigger_email_alert)
      processor.process(document_with_no_topics_key, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "discards the message if there's a JSON parser error" do
      processor.process('{]$£$*()}', delivery_info)

      expect(channel).to have_received(:reject).with(
        delivery_tag,
        false
      )
    end

    it "notifies errbit if there's a JSON parser error" do
      expect(Airbrake).to receive(:notify_or_ignore).with(MalformedDocumentError)
      processor.process('{]$£$*()}', delivery_info)
    end
  end
end
