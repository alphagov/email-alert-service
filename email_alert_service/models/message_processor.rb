require "models/email_alert"
require "models/message"
require "workers/email_alert_worker"

class MessageProcessor
  def initialize(channel, logger)
    @channel = channel
    @logger = logger
  end

  def process(document_json, properties, delivery_info)
    message = Message.new(document_json, properties, delivery_info)

    unless message.heartbeat?
      document = message.validate_document
      trigger_email_alert(document) if tagged_to_topics?(document)
    end

    acknowledge(message)
  rescue MalformedDocumentError => e
    Airbrake.notify_or_ignore(e)
    discard(delivery_info.delivery_tag)
  end

private

  attr_reader :channel

  def trigger_email_alert(document)
    EmailAlert.new(document, @logger, EmailAlertWorker).trigger
  end

  def tagged_to_topics?(document)
    details = document.fetch("details")
    if details.has_key?("tags") && details.fetch("tags").has_key?("topics")
      details.fetch("tags").fetch("topics").any?
    else
      false
    end
  end

  def acknowledge(message)
    channel.acknowledge(message.delivery_tag, false)
  end

  def discard(delivery_tag)
    channel.reject(delivery_tag, false)
  end
end
