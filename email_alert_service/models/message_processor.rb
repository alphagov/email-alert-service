class MessageProcessor
  def initialize(logger)
    @logger = logger
  end

  def process(message)
    process_message(message)

    message.ack
  rescue GdsApi::HTTPErrorResponse => e
    @logger.info "Requeuing '#{document_json['title']}' due to a #{e.code} response"
    message.retry
  rescue MalformedDocumentError => e
    GovukError.notify(e)
    message.discard
  end

protected

  attr_reader :channel

  def process_message(_message)
    raise("This method should be called in a subclass.")
  end
end
