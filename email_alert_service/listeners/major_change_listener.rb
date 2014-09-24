require "bunny"
require "json"

class MajorChangeListener
  def initialize(rabbitmq_options)
    @connection = Bunny.new(rabbitmq_options)
    @exchange_name = rabbitmq_options.fetch("exchange")
    @queue_name = rabbitmq_options.fetch("queue")
    @routing_key = "*.major.#" # Supports future expansions
  end

  def run
    connection.start

    @channel = connection.create_channel
    exchange = channel.topic(@exchange_name, passive: true)

    queue = channel.queue(@queue_name)
    queue.bind(exchange, routing_key: @routing_key)

    puts "Bound to exchange #{@exchange_name} on queue #{@queue_name}, listening for major changes"

    queue.subscribe(block: true, manual_ack: true) do |delivery_info, _, document_json|
      begin
        document = JSON.parse(document_json)

        puts "Recevied major change notification for #{document["title"]}"

        acknowledge(delivery_info)
      rescue JSON::ParserError => e
        discard(delivery_info)
      end
    end
  end

  def stop
    channel.close if channel
    connection.close if connection
  end

private

  attr_reader :connection, :channel

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
