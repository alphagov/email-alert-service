require "handlers/major_change_handler"

class MajorChangeListener
  def initialize(rabbitmq_options, logger)
    @connection = Bunny.new(rabbitmq_options)
    @exchange_name = rabbitmq_options.fetch(:exchange)
    @queue_name = rabbitmq_options.fetch(:queue)
    @routing_key = "*.major.#" # Supports future expansions
    @logger = logger
  end

  def start
    connection.start

    @channel = connection.create_channel
    exchange = channel.topic(@exchange_name, passive: true)

    queue = channel.queue(@queue_name)
    queue.bind(exchange, routing_key: @routing_key)

    @logger.info "Bound to exchange #{@exchange_name} on queue #{@queue_name}, listening for major changes"

    queue.subscribe(block: true, manual_ack: true) do |delivery_info, _, document_json|
      handler.handle(delivery_info, document_json)
    end
  end

  def stop
    channel.close if channel
    connection.close
  end

private

  attr_reader :connection, :channel

  def handler
    @handler ||= MajorChangeHandler.new(channel, @logger)
  end
end
