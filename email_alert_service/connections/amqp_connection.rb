require "bunny"

class AMQPConnection
  # Only fetch one message at a time on the channel.
  #
  # By default, queues will grab messages eagerly, which reduces latency.
  # However, that also means that if multiple workers are running one worker
  # can starve another of work.  We're not expecting a high throughput on this
  # queue, and a small bit of latency isn't a problem, so we fetch one at a
  # time to share the work evenly.
  NUMBER_OF_MESSAGES_TO_PREFETCH = 1

  def initialize(amqp_options, exchange_name)
    @amqp_options = amqp_options
    @exchange_name = exchange_name
  end

  def start
    @start ||= service.start
  end

  def stop
    channel.close if channel
    service.stop
  end

  def channel
    @channel ||= create_channel_and_set_prefetch
  end

  def create_channel_and_set_prefetch
    channel = service.create_channel
    channel.prefetch(NUMBER_OF_MESSAGES_TO_PREFETCH)
    channel
  end

  def exchange
    channel.topic(@exchange_name, passive: true)
  end

private

  attr_reader :options

  def service
    @service ||= Bunny.new(@amqp_options)
  end
end
