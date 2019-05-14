require_relative '../../email_alert_service/environment.rb'

namespace :message_queues do
  logger = EmailAlertService.config.logger
  rabbitmq_options = EmailAlertService.config.rabbitmq

  exchange_name = rabbitmq_options[:exchange]

  desc "Run worker to consume major change messages from rabbitmq"
  task :major_change_consumer do
    logger.info "Bound to exchange #{exchange_name} on major change queue"
    begin
      GovukMessageQueueConsumer::Consumer.new(
        queue_name: "email_alert_service",
        processor: MajorChangeMessageProcessor.new(logger),
        logger: logger
      ).run
    rescue SignalException => e
      logger.info "Signal Exception: #{e}"
      exit 1
    rescue StandardError => e
      logger.info "Error: #{e}"
      exit 1
    end
  end

  desc "Run worker to consume unpublishing messages from rabbitmq"
  task :unpublishing_consumer do
    logger.info "Bound to exchange #{exchange_name} on email_unpublishing queue"
    begin
      GovukMessageQueueConsumer::Consumer.new(
        queue_name: "email_unpublishing",
        processor: UnpublishingMessageProcessor.new(logger),
        logger: logger
      ).run
    rescue SignalException => e
      logger.info "Signal Exception: #{e}"
      exit 1
    rescue StandardError => e
      logger.info "Error: #{e}"
      exit 1
    end
  end
end
