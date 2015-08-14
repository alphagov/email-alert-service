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

    if tagged_to_topics?(document)
      @logger.info "triggering email alert for document #{document["title"]}"
      trigger_email_alert(document)
    end
  end

  attr_reader :channel

  def trigger_email_alert(document)
    EmailAlert.new(document, @logger).trigger
  end

  def tagged_to_topics?(document)
    details = document.fetch("details")
    if details.has_key?("tags") && details.fetch("tags").has_key?("topics")
      details.fetch("tags").fetch("topics").any?
    else
      false
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
