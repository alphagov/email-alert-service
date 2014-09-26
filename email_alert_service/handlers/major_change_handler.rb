require "json"

class MajorChangeHandler
  def initialize(channel, logger)
    @channel = channel
    @logger = logger
  end

  def handle(delivery_info, document_json)
    document = JSON.parse(document_json)

    if document["title"]
      @logger.info "Received major change notification for #{document["title"]}"
    end

    acknowledge(delivery_info)
  rescue JSON::ParserError => e
    discard(delivery_info)
  end

private

  attr_reader :channel

  def acknowledge(delivery_info)
    channel.acknowledge(delivery_info.delivery_tag, false)
  end

  def discard(delivery_info)
    channel.reject(delivery_info.delivery_tag, false)
  end

  def requeue(delivery_info)
    channel.reject(delivery_info.delivery_tag, true)
  end
end
