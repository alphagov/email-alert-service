require "spec_helper"

RSpec.describe Message do
  let(:delivery_info) { double(:delivery_info, delivery_tag: "tag") }
  let(:document_json) { double(:document_json) }
  let(:properties) { double(:properties, content_type: nil) }

  describe "#validate_document" do
    it "returns a parsed, valid document" do
      document_json =
        '{
            "base_path": "path/to-doc",
            "title": "Example title",
            "description": "example description",
            "public_updated_at": "2014-10-06T13:39:19.000+00:00",
            "details": {
              "change_note": "this doc has been changed",
              "tags": {
                "browse_pages": [],
                "topics": ["example topic"]
              }
            }
         }'

      valid_json = JSON.parse(document_json)
      message = Message.new(document_json, properties, delivery_info)

      expect(message.validate_document).to eq valid_json
    end
  end

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
