require "spec_helper"

RSpec.describe DocumentValidator do
  describe "#valid?" do
    it "returns true for a valid document" do
      document =
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

      validator = DocumentValidator.new(document)
      expect(validator.valid?).to eq true
    end

    it "raises an InvalidDocumentKeys error for an invalid document" do
      document = { "title" => "invalid document" }

      validator = DocumentValidator.new(document)
      expect { validator.valid? }.to raise_error(InvalidDocumentKeys)
    end
  end
end
