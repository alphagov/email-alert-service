class DocumentValidator
  REQUIRED_KEYS = %w(base_path title public_updated_at).freeze

  def initialize(document)
    @document = document
  end

  def valid?
    has_all_required_keys?
  end

  def validate!
    return if valid?
    raise InvalidDocumentError.new(self)
  end

private

  attr_reader :document

  def has_all_required_keys?
    REQUIRED_KEYS.all? { |key| document.has_key?(key) }
  end
end

class InvalidDocumentError < StandardError; end
