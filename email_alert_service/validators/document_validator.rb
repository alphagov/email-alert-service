class DocumentValidator
  REQUIRED_KEYS = %w(base_path title description public_updated_at details).freeze

  def initialize(document)
    @document = document
  end

  def valid?
    if document_has_required_keys?
      true
    else
      raise InvalidDocumentKeys
    end
  end

  private

  attr_reader :document

  def document_has_required_keys?
    REQUIRED_KEYS.all? { |key| document.has_key?(key) } &&
      document.fetch("details").has_key?("tags")
  end
end

class InvalidDocumentKeys < Exception; end
