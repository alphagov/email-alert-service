require "spec_helper"

RSpec.describe EmailAlert do
  describe "#trigger" do
    it "logs receiving a major change notification for a document" do
      document = { "title" => "document title", "details" => { "tags" => { "topics" => ["a topic"]  } } }
      logger = double(:logger, info: nil)
      worker = double(:worker, perform_async: nil)
      email_alert = EmailAlert.new(document, logger, worker)
      allow(email_alert).to receive(:format_for_email_api).and_return(nil)

      expect(logger).to receive(:info).with(
        "Received major change notification for #{document["title"]}, with topics #{document["details"]["tags"]["topics"]}")

      email_alert.trigger
    end

    it "queues a formatted alert in the worker" do
      document = { "title" => "document title", "details" => { "tags" => { "topics" => ["a topic"]  } } }
      logger = double(:logger, info: nil)
      worker = double(:worker)
      formatted_for_email_api = double(:formatted_for_email_api)
      email_alert = EmailAlert.new(document, logger, worker)
      allow(email_alert).to receive(:format_for_email_api).and_return(formatted_for_email_api)

      expect(worker).to receive(:perform_async).with(formatted_for_email_api)

      email_alert.trigger
    end
  end

  describe "#format_for_email_api" do
    it "formats the message to send to the email alert api" do
      document = {
        "title" => "Example title",
        "description" => "example description",
        "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
        "details" => {
          "change_note" => "this doc has been changed",
          "tags" => {
            "browse_pages" => [],
            "topics" => [],
          }
        }
      }

      logger = double(:logger)
      worker = double(:worker)

      formatted_message = {
        "subject" => document["title"],
        "body" => "HTML formatted body",
        "tags" => {
          "browse_pages" => [],
          "topics" => [],
        },
      }

      email_alert = EmailAlert.new(document, logger, worker)
      allow(email_alert).to receive(:format_email_body).and_return("HTML formatted body")

      expect(email_alert.format_for_email_api).to eq (formatted_message)
    end
  end
end
