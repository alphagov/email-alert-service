require_relative("./message_processor")

class SubscriberListDetailsUpdateProcessor < MessageProcessor
protected

  def process_message(message)
    document = message.payload

    unless has_content_id?(document)
      @logger.info "not triggering subscriber list update for a document with no content_id: #{document}"
      return
    end

    unless has_title?(document)
      @logger.info "not triggering subscriber list update for a document with no title: #{document}"
      return
    end

    unless is_english?(document)
      @logger.info "not triggering subscriber list update for a non-english document #{document['title']}: locale #{document['locale']}"
      return
    end

    @logger.info "triggering subscriber list update for document: #{document['title']}"
    trigger_subscriber_list_update(document)
  end

private

  attr_reader :logger

  def trigger_subscriber_list_update(document)
    UpdateSubscriberList.new(document, logger).trigger
  end
end
