require "bunny"

class AMQPConnection
  attr_reader :exchange_name, :queue_name

  # Only fetch one message at a time on the channel.
  #
  # By default, queues will grab messages eagerly, which reduces latency.
  # However, that also means that if multiple workers are running one worker
  # can starve another of work.  We're not expecting a high throughput on this
  # queue, and a small bit of latency isn't a problem, so we fetch one at a
  # time to share the work evenly.
  NUMBER_OF_MESSAGES_TO_PREFETCH = 1

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
    @_channel ||= create_channel_and_set_prefetch
  end

  def create_channel_and_set_prefetch
    channel = service.create_channel
    channel.prefetch(NUMBER_OF_MESSAGES_TO_PREFETCH)
    channel
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
