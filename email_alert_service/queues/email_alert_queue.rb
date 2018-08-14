class EmailAlertQueue
  attr_reader :processor_class

  def initialize(connection:, routing_key:, name:)
    @connection = connection
    @routing_key = routing_key
    @name = name
  end

  def bind
    queue.bind(exchange, routing_key: @routing_key)
  end

private

  attr_reader :connection

  def channel
    connection.channel
  end

  def queue
    channel.queue(@name, durable: true)
  end

  def exchange
    connection.exchange
  end
end
