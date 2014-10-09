require "bunny"

class AMQPConnection
  attr_reader :exchange_name, :queue_name

  def initialize(options)
    @options = options
    @exchange_name = options.fetch(:exchange)
    @queue_name = options.fetch(:queue)
  end

  def start
    @_service_connection ||= service.start
  end

  def stop
    channel.close if channel
    service.stop
  end

  def channel
    @_channel ||= service.create_channel
  end

  def exchange
    channel.topic(exchange_name, passive: true)
  end

private

  attr_reader :options

  def service
    @_service ||= Bunny.new(options)
  end
end
