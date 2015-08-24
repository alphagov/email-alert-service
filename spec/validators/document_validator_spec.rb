require "spec_helper"

RSpec.describe DocumentValidator do
  describe "#valid?" do
    let(:valid_document) {
      {
        "base_path" => "path/to-doc",
        "title" => "Example title",
        "description" => "example description",
        "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
        "details" => {
          "change_note" => "this doc has been changed",
          "tags" => {
            "browse_pages" => [],
            "topics" => []
          }
        }
      }
    }

    let(:valid_document_no_details) {
      {
        "base_path" => "path/to-doc",
        "title" => "Example title",
        "description" => "example description",
        "public_updated_at" => "2014-10-06T13:39:19.000+00:00",
      }
    }

    let(:invalid_document) { {"title" => "invalid document"} }

    it "returns true for a valid document" do
      expect(DocumentValidator.new(valid_document)).to be_valid
    end

    it "returns true for a valid document with no details hash" do
      expect(DocumentValidator.new(valid_document_no_details)).to be_valid
    end

    it "returns false for an invalid document" do
      expect(DocumentValidator.new(invalid_document)).to_not be_valid
    end
  end
end
