require "spec_helper"

RSpec.describe DocumentValidator do
  describe "#valid?" do
    let(:base_document)  {
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

    it "raises InvalidDocument for a document that is not tagged to topics" do
      validator = DocumentValidator.new(base_document)

      expect { validator.valid? }.to raise_error(InvalidDocument)
    end

    it "returns true for a valid document" do
      valid_document = base_document.merge(
        {
          "details" => {
          "tags" => {
            "topics" => ["example topic"]
            }
          }
        })

      validator = DocumentValidator.new(valid_document)
      expect(validator).to be_valid
    end

    it "raises an InvalidDocument error for an invalid document" do
      document = { "title" => "invalid document" }

      validator = DocumentValidator.new(document)
      expect { validator.valid? }.to raise_error(InvalidDocument)
    end
  end
end
