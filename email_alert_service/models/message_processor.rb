require "models/email_alert"
require "models/message"

class MessageProcessor
  def initialize(channel, logger)
    @channel = channel
    @logger = logger
  end

  def process(document_json, properties, delivery_info)
    message = Message.new(document_json, properties, delivery_info)

    process_message(message)

    acknowledge(message)
  rescue InvalidDocumentError, MalformedDocumentError => e
    Airbrake.notify_or_ignore(e)
    discard(delivery_info.delivery_tag)
  end

private

  def process_message(message)
    return if message.heartbeat?

    document = message.parsed_document

    unless has_title?(document)
      @logger.info "not triggering email alert for document with no title: #{document}"
      return
    end

    unless is_english?(document)
      @logger.info "not triggering email alert for non-english document #{document["title"]}: locale #{document["locale"]}"
      return
    end

    message.validate!

    if email_alerts_supported?(document)
      @logger.info "triggering email alert for document #{document["title"]}"
      trigger_email_alert(document)
    end
  end

  attr_reader :channel

  def trigger_email_alert(document)
    EmailAlert.new(document, @logger).trigger
  end

  def email_alerts_supported?(document)
    document_tags = document.fetch("details", {}).fetch("tags", {})
    document_links = document.fetch("links", {})
    contains_supported_tag?(document_links) || contains_supported_tag?(document_tags)
  end

  def contains_supported_tag?(tags_hash)
    supported_tag_names = ["topics", "policies"]
    supported_tag_names.any? do |tag_name|
      tags_hash[tag_name] && tags_hash[tag_name].any?
    end
  end

  def is_english?(document)
    document.fetch("locale", "en") == "en"
  end

  def has_title?(document)
    document.fetch("title", "") != ""
  end

  def acknowledge(message)
    channel.acknowledge(message.delivery_tag, false)
  end

  def discard(delivery_tag)
    channel.reject(delivery_tag, false)
  end
end
