module MessageProcessorValidator
  def valid?(document)
    unless has_base_path?(document)
      @logger.info "not triggering email alert for document with no base_path: #{document}"
      return false
    end

    unless has_title?(document)
      @logger.info "not triggering email alert for document with no title: #{document}"
      return false
    end

    unless has_public_updated_at?(document)
      @logger.info "not triggering email alert for document with no public_updated_at: #{document}"
      return false
    end

    unless is_english?(document)
      @logger.info "not triggering email alert for non-english document #{document['title']}: locale #{document['locale']}"
      return false
    end

    unless has_change_note?(document)
      @logger.info "not triggering email alert for document missing change note #{document}"
      return false
    end

    true
  end

private

  def is_english?(document)
    # A missing locale is assumed to be English, but a "null" locale is not
    return true unless document.key?("locale")

    document["locale"] == "en"
  end

  def has_base_path?(document)
    has_non_blank_value_for_key?(document: document, key: "base_path")
  end

  def has_title?(document)
    has_non_blank_value_for_key?(document: document, key: "title")
  end

  def has_public_updated_at?(document)
    has_non_blank_value_for_key?(document: document, key: "public_updated_at")
  end

  def has_change_note?(document)
    note = ChangeHistory.new(
      history: document.dig("details", "change_history")
    ).latest_change_note

    !note.nil? && !note.empty?
  end

  def has_non_blank_value_for_key?(document:, key:)
    # a key can be present but the value is nil, so fetch won't
    # protect us here
    return false unless document.key?(key)

    (document[key] || "") != ""
  end
end
