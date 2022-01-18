require "spec_helper"

RSpec.describe MessageProcessor do
  include MessageProcessorHelpers

  let(:logger) { double(:logger, info: nil) }

  let(:processor) do
    Class.new(MessageProcessor).new(logger)
  end

  let(:message) do
    double(
      :message_queue_consumer_message,
      ack: nil,
      discard: nil,
      retry: nil,
      payload: "title['test']",
    )
  end

  describe "#process" do
    context "message successfully processed" do
      it "acknowledges the message" do
        def processor.process_message(_message)
          true
        end
        processor.process(message)
        message_acknowledged
      end
    end
    context "document contains malformed JSON" do
      it "rejects the document and notifies an exception reporter" do
        def processor.process_message(_message)
          raise StandardError
        end
        processor.process(message)
        message_rejected
      end
    end

    context "email alert api returns an error" do
      it "requeues the message" do
        def processor.process_message(_message)
          raise GdsApi::HTTPBadGateway.new(502, "Bad Request")
        end
        processor.process(message)
        message_requeued
      end
    end
  end
end
