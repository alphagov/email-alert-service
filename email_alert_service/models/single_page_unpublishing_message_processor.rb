require_relative("./message_processor")

class SinglePageUnpublishingMessageProcessor < MessageProcessor
protected

  def process_message(message)
    @document = message.payload

    unless has_base_path?(document)
      @logger.info "not triggering bulk unsubscription and alert for document with no base_path: #{document}"
      return
    end

    unless has_public_updated_at?(document)
      @logger.info "not triggering bulk unsubscription and alert for document with no public_updated_at: #{document}"
      return
    end

    unless is_english?(document)
      @logger.info "not triggering email alert for non-english document #{document['title']}: locale #{document['locale']}"
      return
    end

    unless has_content_id?(document)
      @logger.info "not triggering bulk unsubscription and alert for document with no content_id: #{document}"
      return
    end

    unpublishing_scenario_string = unpublishing_scenario

    unless unpublishing_scenario_string
      @logger.info "not triggering bulk unsubscription and alert for document with a unknown unpublishing scenario. Document type: #{document['document_type']}"
      return
    end

    UnpublishingAlert.new(@document, @logger, unpublishing_scenario_string).trigger
  end

private

  attr_reader :document

  def unpublishing_scenario
    if was_published_in_error?
      if has_alternative_url?
        "published_in_error_with_url"
      else
        "published_in_error_without_url"
      end
    elsif was_consolidated?
      "consolidated"
    end
  end

  def was_consolidated?
    document["document_type"] == "redirect"
  end

  def has_alternative_url?
    document.dig("details", "alternative_path").present?
  end

  def was_published_in_error?
    document["document_type"] == "gone"
  end

  def has_content_id?(document)
    has_non_blank_value_for_key?(document: document, key: "content_id")
  end
end
