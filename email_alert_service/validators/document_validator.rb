class DocumentValidator
  REQUIRED_KEYS = %w(base_path title description public_updated_at details).freeze

  def initialize(document)
    @document = document
  end

  def valid?
    if has_all_required_keys?
      true
    else
      false
    end
  end

private

  attr_reader :document

  def has_all_required_keys?
    REQUIRED_KEYS.all? { |key| document.has_key?(key) }
  end
end
