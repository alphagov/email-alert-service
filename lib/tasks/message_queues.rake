require_relative "../../email_alert_service/environment"

namespace :message_queues do
  logger = EmailAlertService.config.logger
  rabbitmq_options = EmailAlertService.config.rabbitmq

  exchange_name = rabbitmq_options[:exchange]

  desc "Create the queues that Email Alert Service uses with Rabbit MQ"
  task :create_queues do
    config = GovukMessageQueueConsumer::RabbitMQConfig.from_environment(ENV)
    bunny = Bunny.new(config)
    channel = bunny.start.create_channel
    exchange = Bunny::Exchange.new(channel, :topic, exchange_name)

    rabbitmq_options[:queues].each do |queue|
      channel.queue(queue[:name]).bind(exchange, routing_key: queue[:routing_key])
    end
  end

  desc "Run worker to consume major change messages from rabbitmq"
  task :major_change_consumer do
    run_processor_worker(
      MajorChangeMessageProcessor,
      "email_alert_service",
      exchange_name,
      logger,
    )
  end

  desc "Run worker to consume unpublishing messages from rabbitmq"
  task :unpublishing_consumer do
    run_processor_worker(
      EmailUnpublishingProcessor,
      "email_unpublishing",
      exchange_name,
      logger,
    )
  end

  desc "Run workers to consume subscriber list updates for major change messages from rabbitmq"
  task :subscriber_list_details_update_major_consumer do
    run_processor_worker(
      SubscriberListDetailsUpdateProcessor,
      "subscriber_list_details_update_major",
      exchange_name,
      logger,
    )
  end

  desc "Run workers to consume subscriber list updates for minor change messages from rabbitmq"
  task :subscriber_list_details_update_minor_consumer do
    run_processor_worker(
      SubscriberListDetailsUpdateProcessor,
      "subscriber_list_details_update_minor",
      exchange_name,
      logger,
    )
  end
end

def run_processor_worker(processor, queue_name, exchange_name, logger)
  logger.info "Bound to exchange #{exchange_name}"
  begin
    GovukError.configure
    EmailAlertService.services(:redis)
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: queue_name,
      processor: processor.new(logger),
      logger: logger,
    ).run
  rescue SignalException => e
    logger.info "Signal Exception: #{e}"
    exit 1
  rescue StandardError => e
    logger.info "Error: #{e}"
    exit 1
  end
end
