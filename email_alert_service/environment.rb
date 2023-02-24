require "bundler/setup"
require "bootsnap"
Bootsnap.setup(
  cache_dir: ENV.fetch("BOOTSNAP_CACHE_DIR", "tmp/cache"),
  development_mode: ENV["RACK_ENV"] == "development",
)

require_relative "../config/prometheus"
require_relative "config"

module EmailAlertService
  def self.config
    EmailAlertService::Config.new(ENV["GOVUK_ENV"])
  end

  def self.run_processor(processor_class, queue_name)
    Process.fork do
      Process.setproctitle("#{$PROGRAM_NAME} [#{queue_name}]")
      logger = EmailAlertService.config.logger
      exchange_name = EmailAlertService.config.rabbitmq[:exchange]
      logger.info "Starting #{processor_class} for queue #{queue_name} on exchange #{exchange_name}"
      GovukError.configure
      EmailAlertService.services(:redis)
      processor = processor_class.new(logger)
      GovukMessageQueueConsumer::Consumer.new(queue_name:, processor:, logger:).run
    end
  end
end

$LOAD_PATH.append(
  EmailAlertService.config.app_root.to_s,
  "#{EmailAlertService.config.app_root}/email_alert_service",
)

Bundler.require(:default, EmailAlertService.config.environment)

require "govuk_app_config"

EmailAlertService.config.logger.level = Logger::DEBUG

Dir.glob("email_alert_service/**/*.rb").sort.each { |r| require r }

Dir[File.join(EmailAlertService.config.app_root, "config/initializers/**/*.rb")].sort.each { |f| require f }
