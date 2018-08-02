require "spec_helper"

RSpec.describe MessageProcessor do
  let(:delivery_tag) { double(:delivery_tag) }
  let(:delivery_info) { double(:delivery_info, delivery_tag: delivery_tag) }
  let(:properties) { double(:properties, content_type: nil) }

  let(:channel) { double(:channel, acknowledge: nil, reject: nil, nack: nil) }
  let(:logger) { double(:logger, info: nil) }

  let(:processor) {
    Class.new(MessageProcessor).new(channel, logger)
  }

  def message_acknowledged
    expect(channel).to have_received(:acknowledge).with(delivery_tag, false)
  end

  def message_rejected
    expect(channel).to have_received(:reject).with(delivery_tag, false)
  end

  def message_requeued
    expect(channel).to have_received(:nack).with(delivery_tag, false, true)
  end

  describe "#process" do
    context "document contains malformed JSON" do
      it "rejects the document and notifies an exception reporter" do
        def processor.process_message(_)
          raise MalformedDocumentError
        end
        processor.process({}.to_json, properties, delivery_info)
        message_rejected
      end
    end

    context "email alert api returns an error" do
      it "requeues the message" do
        def processor.process_message(_)
          raise GdsApi::HTTPBadGateway.new(502, "Bad Request")
        end
        processor.process({}.to_json, properties, delivery_info)
        message_requeued
      end
    end

    context "content type identifies the document as a heartbeat" do
      it "acknowledges" do
        properties = double(:properties, content_type: "application/x-heartbeat")
        processor.process({}.to_json, properties, delivery_info)
        message_acknowledged
      end
    end

  end
end
