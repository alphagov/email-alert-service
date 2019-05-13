class MessageProcessor
  def initialize(logger)
    @logger = logger
  end

  def process(message)
    process_message(message)

    message.ack
  rescue GdsApi::HTTPErrorResponse => e
    @logger.info "Requeuing '#{message.payload['title']}' due to a #{e.code} response"
    message.retry
  rescue StandardError => e
    GovukError.notify(e)
    message.discard
  end

protected

  def process_message(_message)
    raise("This method should be called in a subclass.")
  end
end
