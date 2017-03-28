require "spec_helper"

RSpec.describe Message do
  let(:delivery_info) { double(:delivery_info, delivery_tag: "tag") }
  let(:document_json) { double(:document_json) }
  let(:properties) { double(:properties, content_type: nil) }

  describe "#delivery_tag" do
    it "returns the delivery tag from the delivery info" do
      message = Message.new(document_json, properties, delivery_info)

      expect(message.delivery_tag).to eq "tag"
    end
  end

  describe "#heartbeat?" do
    it "is true if the content type matches" do
      properties = double(:properties, content_type: "application/x-heartbeat")
      message = Message.new(document_json, properties, delivery_info)
      expect(message).to be_heartbeat
    end

    it "is false if the content type does not match" do
      properties = double(:properties, content_type: "application/javascript")
      message = Message.new(document_json, properties, delivery_info)
      expect(message).not_to be_heartbeat

      properties = double(:properties, content_type: nil)
      message = Message.new(document_json, properties, delivery_info)
      expect(message).not_to be_heartbeat
    end
  end
end
