require "spec_helper"

RSpec.describe MessageProcessor do
  let(:logger) { double(:logger, info: nil) }

  let(:processor) {
    Class.new(MessageProcessor).new(logger)
  }

  let(:message) { double(:message_queue_consumer_message, ack: nil, discard: nil, 
                          retry: nil, payload: "title['test']") } 

  def message_acknowledged
    expect(message).to have_received(:ack)
  end

  def message_rejected
    expect(message).to have_received(:discard)
  end

  def message_requeued
    expect(message).to have_received(:retry)
  end

  describe "#process" do
    context "message successfully processed" do
      it "acknowledges the message" do
        def processor.process_message(_message)
          return true
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
