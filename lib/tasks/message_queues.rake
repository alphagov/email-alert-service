require_relative '../../email_alert_service/environment.rb'

namespace :message_queues do
  desc "Run worker to consume messages from rabbitmq"
  task :consumer do
    logger = EmailAlertService.config.logger
    rabbitmq_options = EmailAlertService.config.rabbitmq

    exchange_name = rabbitmq_options[:exchange]

    rabbitmq_options[:queues].each do |queue|
      logger.info "Bound to exchange #{exchange_name} on queue #{queue[:name]}"
      begin
        GovukMessageQueueConsumer::Consumer.new(
          queue_name: queue[:name],
          processor: queue[:processor].camelize.constantize.new(logger),
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
end
