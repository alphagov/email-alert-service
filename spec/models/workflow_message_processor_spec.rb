require "spec_helper"

RSpec.describe WorkflowMessageProcessor do
  let(:delivery_tag) { double(:delivery_tag) }
  let(:delivery_info) { double(:delivery_info, delivery_tag: delivery_tag) }
  let(:properties) { double(:properties, content_type: nil) }
  let(:channel) { double(:channel, acknowledge: nil, reject: nil, nack: nil) }
  let(:logger) { double(:logger, info: nil) }

  let(:processor) { WorkflowMessageProcessor.new(channel, logger) }
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
      "publishing_app" => "content-tagger",
      "details" => {
        "change_history" => change_history,
      },
      "links" => {
        "facet_groups" => ["example-facet-group-uuid"],
        "facet_values" => ["example-facet-value-uuid"],
      },
      "workflow_message" => "Something important changed",
    }
  end

  def email_was_triggered
    expect(mock_email_alert).to have_received(:trigger)
  end

  def email_was_not_triggered
    expect(mock_email_alert).to_not have_received(:trigger)
  end

  def message_acknowledged
    expect(channel).to have_received(:acknowledge).with(delivery_tag, false)
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

    context "document with empty tags" do
      before do
        good_document["details"]["tags"] = { "facet_groups" => [], "facet_values" => [] }
        good_document["links"] = { "facet_groups" => [], "facet_values" => [] }
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "document with missing tag fields" do
      before do
        good_document["links"].delete("facet_groups")
        good_document["details"].delete("tags")
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "empty change note" do
      before do
        good_document["details"]["change_history"][0]["note"] = ""
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "missing change history" do
      before do
        good_document["details"]["change_history"] = nil
      end

      it "acknowledges but doesn't trigger the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "missing details hash" do
      before { good_document.delete("details") }

      it "acknowledges but doesn't trigger the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end

    context "missing links hash" do
      before { good_document.delete("links") }

      it "still acknowledges but doesn't trigger the email" do
        processor.process(good_document.to_json, properties, delivery_info)

        email_was_not_triggered
        message_acknowledged
      end
    end
  end
end
