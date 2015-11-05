require "spec_helper"
require "models/message_processor"
require "govuk_message_queue_consumer/test_helpers"

RSpec.describe MessageProcessor do
  before { allow(EmailAlert).to receive(:trigger) }

  it_behaves_like "a message queue processor"

  describe "#process" do
    it "triggers an email if the document has topics" do
      message = GovukMessageQueueConsumer::MockMessage.new(
        {
          "base_path" => "/foo/bar",
          "title" => "A Title",
          "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
          "locale" => "en",
          "details" => {
            "tags" => {
              "topics" => ["mah-topic"]
            }
          }
        },
        {},
        { routing_key: "topic.major" }
      )

      MessageProcessor.new.process(message)

      expect(message).to be_acked
      expect(EmailAlert).to have_received(:trigger)
    end

    it "triggers an email if the document has policy" do
      message = GovukMessageQueueConsumer::MockMessage.new(
        {
          "base_path" => "/foo/bar",
          "title" => "A Title",
          "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
          "locale" => "en",
          "details" => {
            "tags" => {
              "policy" => ["mah-policy"]
            }
          }
        },
        {},
        { routing_key: "policy.major" }
      )

      MessageProcessor.new.process(message)

      expect(message).to be_acked
      expect(EmailAlert).to have_received(:trigger)
    end

    it "does not trigger an email without a title" do
      message = GovukMessageQueueConsumer::MockMessage.new(
        {
          "base_path" => "/foo/bar",
          "title" => "",
          "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
          "locale" => "en",
          "details" => {
            "tags" => {
              "policy" => ["mah-policy"]
            }
          }
        },
        {},
        { routing_key: "policy.major" }
      )

      MessageProcessor.new.process(message)

      expect(message).to be_acked
      expect(EmailAlert).not_to have_received(:trigger)
    end

    it "does not trigger an email not in english" do
      message = GovukMessageQueueConsumer::MockMessage.new(
        {
          "base_path" => "/foo/bar",
          "title" => "",
          "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
          "locale" => "de",
          "details" => {
            "tags" => {
              "policy" => ["mah-policy"]
            }
          }
        },
        {},
        { routing_key: "policy.major" }
      )

      MessageProcessor.new.process(message)

      expect(message).to be_acked
      expect(EmailAlert).not_to have_received(:trigger)
    end

    it "ignores items without a public_updated_at" do
      message = GovukMessageQueueConsumer::MockMessage.new(
        {
          "base_path" => "/foo/bar",
          "title" => "A Title",
          "locale" => "en",
          "details" => {
            "tags" => {
              "policy" => ["mah-policy"]
            }
          }
        },
        {},
        { routing_key: "policy.major" }
      )

      MessageProcessor.new.process(message)

      expect(message).not_to be_acked
      expect(message).to be_discarded
      expect(EmailAlert).not_to have_received(:trigger)
    end
  end
end
