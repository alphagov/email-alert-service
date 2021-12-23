class MessageProcessor
  def initialize(logger)
    @logger = logger
  end

  def process(message)
    process_message(message)

    message.ack
  rescue GdsApi::HTTPErrorResponse => e
    @logger.info "Requeuing '#{message.payload['title']}' due to a #{e.code} response"
    message.retry
  rescue StandardError => e
    GovukError.notify(e)
    message.discard
  end

protected

  def process_message(_message)
    raise("This method should be called in a subclass.")
  end

  def has_base_path?(document)
    has_non_blank_value_for_key?(document: document, key: "base_path")
  end

  def has_public_updated_at?(document)
    has_non_blank_value_for_key?(document: document, key: "public_updated_at")
  end

  def has_non_blank_value_for_key?(document:, key:)
    # a key can be present but the value is nil, so fetch won't
    # protect us here
    return false unless document.key?(key)

    (document[key] || "") != ""
  end

  def is_english?(document)
    # A missing locale is assumed to be English, but a "null" locale is not
    return true unless document.key?("locale")

    document["locale"] == "en"
  end
end
