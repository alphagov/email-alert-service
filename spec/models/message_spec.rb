require "spec_helper"

RSpec.describe Message do
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
                "topics": []
              }
            }
         }'

      valid_json = JSON.parse(document_json)
      delivery_info = double(:delivery_info, delivery_tag: "tag")
      message = Message.new(document_json, delivery_info)

      expect(message.validate_document).to eq valid_json
    end
  end

  describe "#delivery_tag" do
    it "returns the delivery tag from the delivery info" do
      delivery_info = double(:delivery_info, delivery_tag: "tag")
      document_json = double(:document_json)
      message = Message.new(document_json, delivery_info)

      expect(message.delivery_tag).to eq "tag"
    end
  end
end
