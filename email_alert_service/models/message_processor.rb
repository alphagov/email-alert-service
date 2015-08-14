require "models/email_alert"
require "models/message"

class MessageProcessor
  def initialize(channel, logger)
    @channel = channel
    @logger = logger
  end

  def process(document_json, properties, delivery_info)
    message = Message.new(document_json, properties, delivery_info)

    unless message.heartbeat?
      document = message.validate_document
      if tagged_to_topics?(document)
        if is_english?(document)
          if has_title?(document)
            @logger.info "triggering email alert for document #{document["title"]}"
            trigger_email_alert(document)
          else
            @logger.info "not triggering email alert for document with no title: #{document}"
          end
        else
          @logger.info "not triggering email alert for non-english document #{document["title"]}: locale #{document["locale"]}"
        end
      end
    end

    acknowledge(message)
  rescue MalformedDocumentError => e
    Airbrake.notify_or_ignore(e)
    discard(delivery_info.delivery_tag)
  end

private

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
