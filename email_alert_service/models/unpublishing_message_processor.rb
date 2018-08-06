require_relative('./message_processor')

class UnpublishingMessageProcessor < MessageProcessor

protected

  def process_message(message)
    document = message.parsed_document

    Services.email_api_client.send_unpublish_message(document)
  end

end
