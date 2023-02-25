require_relative "../../email_alert_service/environment"

namespace :message_queues do
  desc "Create the queues that Email Alert Service uses with Rabbit MQ"
  task :create_queues do
    config = GovukMessageQueueConsumer::RabbitMQConfig.from_environment(ENV)
    bunny = Bunny.new(config)
    channel = bunny.start.create_channel
    exchange_name = EmailAlertService.config.rabbitmq[:exchange]
    exchange = Bunny::Exchange.new(channel, :topic, exchange_name)

    rabbitmq_options[:queues].each do |queue|
      channel.queue(queue[:name]).bind(exchange, routing_key: queue[:routing_key])
    end
  end
end
