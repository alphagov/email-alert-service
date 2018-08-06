class Listener
  def initialize(queue_binding, processor)
    @processor = processor
    @queue_binding = queue_binding
  end

  def listen
    @queue_binding.subscribe(block: false, manual_ack: true) do |delivery_info, properties, document_json|
      begin
        process_message(document_json, properties, delivery_info)
      rescue SignalException
        exit_on_signal
      rescue Exception => e # rubocop:disable Lint/RescueException
        exit_on_exception(e, document_json, properties, delivery_info)
      end
    end
  end

private

  def process_message(document_json, properties, delivery_info)
    logger.info("Calling process on message #{delivery_info.delivery_tag}")
    @processor.process(document_json, properties, delivery_info)
    logger.info("Processed message #{delivery_info.delivery_tag}")
  end

  def exit_on_signal
    logger.info("Received signal: exiting...")
    exit(0)
  end

  def exit_on_exception(e, document_json, properties, delivery_info)
    logger.info("Error processing message #{delivery_info.delivery_tag}: #{e.class} (#{e.message})")
    # Rescue any exception, not just StandardError and subclasses.
    # We want to ensure that the process exits in such a situation, so we
    # explicitly call exit() after logging the error.
    GovukError.notify(e,
      extra: {
        delivery_info: delivery_info,
        properties: properties,
        payload: document_json,
      })
    exit(1)
  end

  def logger
    EmailAlertService.config.logger
  end
end
