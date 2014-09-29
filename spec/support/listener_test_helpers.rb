require "logger"
require "tempfile"
require "timeout"
require "listeners/major_change_listener"

module ListenerTestHelpers
  def send_message(body, routing_key: "policy.major")
    @exchange.publish(body,
      routing_key: routing_key,
      content_type: "application/json"
    )
    sleep 0.1
  end

  def build_listener(logger)
    MajorChangeListener.new(@test_config.rabbitmq, logger)
  end

  def start_listener
    logfile = Tempfile.new("email_alert_service_test_log")
    logfile.sync = true

    logger = Logger.new(logfile)

    listener = build_listener(logger)
    thread = Thread.new do
      listener.start
    end

    return [logfile, thread, listener]
  end

  def wait_for_messages_to_process
    Timeout.timeout(5) do
      while @read_queue.message_count > 0
        sleep 0.1
      end
    end
  end
end
