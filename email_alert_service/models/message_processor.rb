require "models/email_alert"
require "models/message"
require "workers/email_alert_worker"

class MessageProcessor
  def initialize(channel, logger)
    @channel = channel
    @logger = logger
  end

  def process(document_json, delivery_info)
    message = Message.new(document_json, delivery_info)
    document = message.validate_document
    trigger_email_alert(document)
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

  def acknowledge(message)
    channel.acknowledge(message.delivery_tag, false)
  end

  def discard(delivery_tag)
    channel.reject(delivery_tag, false)
  end
end
