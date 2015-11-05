class MessageProcessor
  def process(message)
    ensure_only_major_updates!(message)
    content_item = message.payload

    DocumentValidator.new(content_item).validate!
    process_message(content_item)
    message.ack
  rescue InvalidDocumentError => e
    Airbrake.notify_or_ignore(e)
    message.discard
  end

private

  def process_message(content_item)
    unless has_title?(content_item)
      logger.info "not triggering email alert for content_item with no title: #{content_item}"
      return
    end

    unless is_english?(content_item)
      logger.info "not triggering email alert for non-english content_item #{content_item["title"]}: locale #{content_item["locale"]}"
      return
    end

    unless has_relevant_tags?(content_item)
      logger.info "not triggering email alert for non-tagged content_item #{content_item["title"]}"
      return
    end

    logger.info "triggering email alert for content_item #{content_item["title"]}"
    EmailAlert.trigger(content_item)
  end

  def has_relevant_tags?(content_item)
    content_item_tags = content_item.fetch("details", {}).fetch("tags", {})
    supported_tag_names = ["topics", "policy"]

    supported_tag_names.any? do |tag_name|
      !(content_item_tags[tag_name].nil? || content_item_tags[tag_name].empty?)
    end
  end

  def is_english?(content_item)
    content_item.fetch("locale", "en") == "en"
  end

  def has_title?(content_item)
    content_item.fetch("title", "") != ""
  end

  def logger
    EmailAlertService.config.logger
  end

  def ensure_only_major_updates!(message)
    update_type = message.delivery_info.routing_key.split('.').last
    return if update_type == 'major'
    raise "Found a message with illegal update: #{update_type}"
  end
end
