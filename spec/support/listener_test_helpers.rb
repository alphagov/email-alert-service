require "connections/amqp_connection"
require "listeners/listener"
require "logger"
require "queues/major_change_queue"
require "tempfile"
require "timeout"

module ListenerTestHelpers
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
    @app_connection = AMQPConnection.new(rabbitmq_options)
    @app_connection.start

    channel = @app_connection.channel

    queue_binding = MajorChangeQueue.new(@app_connection).bind
    message_processor = MessageProcessor.new(channel, logger)
    listener = Listener.new(queue_binding, message_processor)

    @thread = Thread.new do
      listener.listen
    end
  end

  def stop_listener
    @app_connection.stop
    @thread.kill

    while @thread.alive?
      sleep 0.1
    end
  end

  def wait_for_messages_to_process
    Timeout.timeout(5) do
      while @read_queue.message_count > 0
        sleep 0.1
      end
    end
  end
end
