require "spec_helper"
require "models/message_processor"

RSpec.describe MessageProcessor do
  let(:delivery_tag) { double(:delivery_tag) }
  let(:delivery_info) { double(:delivery_info, delivery_tag: delivery_tag) }
  let(:properties) { double(:properties, content_type: nil) }
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

  let(:tagged_english_document) {
    '{
        "base_path": "path/to-doc",
        "title": "Example title",
        "description": "example description",
        "locale": "en",
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

  let(:tagged_french_document) {
    '{
        "base_path": "path/to-doc",
        "title": "Le title",
        "description": "pour example",
        "locale": "fr",
        "public_updated_at": "2014-10-06T13:39:19.000+00:00",
        "details": {
          "change_note": "this doc has been changed, un petit peu",
          "tags": {
            "browse_pages": [],
            "topics": ["example topic one", "example topic two"]
          }
        }
      }'
    }

  let(:tagged_untitled_document) {
    '{
        "base_path": "path/to-doc",
        "locale": "en",
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
      processor.process(tagged_document, properties, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "acknowledges but doesnt trigger the message if the document is not tagged to a topic" do
      expect(processor).to_not receive(:trigger_email_alert)
      processor.process(not_tagged_document, properties, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "acknowledges but doesnt trigger the message if the document does not have a tags key" do
      expect(processor).to_not receive(:trigger_email_alert)
      processor.process(document_with_no_tags_key, properties, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "acknowledges but doesnt trigger the message if the document does not have a topics key" do
      expect(processor).to_not receive(:trigger_email_alert)
      processor.process(document_with_no_topics_key, properties, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "discards the message if there's a JSON parser error" do
      processor.process('{]$£$*()}', properties, delivery_info)

      expect(channel).to have_received(:reject).with(
        delivery_tag,
        false
      )
    end

    it "notifies errbit if there's a JSON parser error" do
      expect(Airbrake).to receive(:notify_or_ignore).with(MalformedDocumentError)
      processor.process('{]$£$*()}', properties, delivery_info)
    end

    it "ignores heartbeat messages" do
      properties = double(:properties, content_type: "application/x-heartbeat")
      expect(processor).not_to receive(:trigger_email_alert)

      # Heartbeats wouldn't be tagged but I want to prove they're ignored
      # based on content type.
      processor.process(tagged_document, properties, delivery_info)


      expect(channel).to have_received(:acknowledge).with(delivery_tag, false)
    end

    it "acknowledges and triggers the message if the document has topics and is english" do
      expect(processor).to receive(:trigger_email_alert)
      processor.process(tagged_english_document, properties, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "ignores the message if the document has topics but is not english" do
      expect(processor).not_to receive(:trigger_email_alert)
      processor.process(tagged_french_document, properties, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "ignores the message if the document has topics but no title" do
      expect(processor).not_to receive(:trigger_email_alert)
      processor.process(tagged_untitled_document, properties, delivery_info)

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end
  end
end
