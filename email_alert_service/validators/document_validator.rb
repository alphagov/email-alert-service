class DocumentValidator
  REQUIRED_KEYS = %w(base_path title description public_updated_at details).freeze

  def initialize(document)
    @document = document
  end

  def valid?
    if document_is_valid?
      true
    else
      raise InvalidDocument
    end
  end

private

  attr_reader :document

  def document_is_valid?
    has_all_required_keys? && is_tagged_to_topics?
  end

  def has_all_required_keys?
    REQUIRED_KEYS.all? { |key| document.has_key?(key) }
  end

  def is_tagged_to_topics?
    document_details["tags"]["topics"].any?
  end

  def document_details
    document.fetch("details")
  end

end

class InvalidDocument < Exception; end
