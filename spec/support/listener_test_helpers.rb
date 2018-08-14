require "logger"
require "tempfile"
require "timeout"

module ListenerTestHelpers
  def with_listener
    start_listener
    yield
    stop_listener
  end

  def send_message(body, routing_key: "policy.major")
    @exchange.publish(
      body,
      routing_key: routing_key,
      content_type: "application/json"
    )
    sleep 0.1
  end

  def start_listener
    logfile = Tempfile.new("email_alert_service_test_log")
    logfile.sync = true
    logger = Logger.new(logfile)

    config = EmailAlertService.config

    rabbitmq_options = config.rabbitmq
    amqp_options = rabbitmq_options[:amqp]
    exhange_name = rabbitmq_options[:exchange]
    queues_options = rabbitmq_options[:queues]

    @app_connection = AMQPConnection.new(amqp_options, exhange_name)
    @app_connection.start

    channel = @app_connection.channel

    listeners = queues_options.map do |queue_options|
      queue = ::EmailAlertQueue.new(connection: @app_connection, routing_key: queue_options[:routing_key], name: queue_options[:name])
      processor = queue_options[:processor].camelize.constantize.new(channel, logger)
      Listener.new(queue.bind, processor)
    end

    @thread = Thread.new do
      listeners.each_with_index do |listener, _index|
        listener.listen
      end
      loop { sleep 5 }
    end
  end

  def stop_listener
    @thread.kill

    while @thread.alive?
      sleep 0.1
    end
    @app_connection.stop
  end

  def wait_for_messages_to_process
    Timeout.timeout(5) do
      while @read_queues.any? { |queue| queue.message_count > 0 }
        sleep 0.1
      end
    end
  end
end
