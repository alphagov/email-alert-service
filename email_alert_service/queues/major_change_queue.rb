class MajorChangeQueue
  MAJOR_CHANGE_ROUTING_KEY = "*.major.#".freeze # Supports future expansions

  def initialize(connection)
    @connection = connection
  end

  def bind
    queue.bind(exchange, routing_key: MAJOR_CHANGE_ROUTING_KEY)
  end

private

  attr_reader :connection

  def channel
    connection.channel
  end

  def queue
    channel.queue(connection.queue_name, durable: true)
  end

  def exchange
    connection.exchange
  end
end
