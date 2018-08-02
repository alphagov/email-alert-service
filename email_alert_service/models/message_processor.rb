class MessageProcessor
  def initialize(channel, logger)
    @channel = channel
    @logger = logger
  end

  def process(document_json, properties, delivery_info)
    message = Message.new(document_json, properties, delivery_info)

    process_message(message) unless message.heartbeat?

    acknowledge(message)
  rescue GdsApi::HTTPErrorResponse => e
    @logger.info "Requeuing '#{document_json['title']}' due to a #{e.code} response"
    requeue(delivery_info.delivery_tag)
  rescue MalformedDocumentError => e
    GovukError.notify(e)
    discard(delivery_info.delivery_tag)
  end

protected

  attr_reader :channel

  def process_message(_message)
    raise("This method should be called in a subclass.")
  end

  def acknowledge(message)
    channel.acknowledge(message.delivery_tag, false)
  end

  def discard(delivery_tag)
    channel.reject(delivery_tag, false)
  end

  def requeue(delivery_tag)
    channel.nack(delivery_tag, false, true)
  end

end
