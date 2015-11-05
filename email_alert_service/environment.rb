require_relative "../email_alert_service/config"

module EmailAlertService
  def self.config
    EmailAlertService::Config.new(ENV["GOVUK_ENV"])
  end
end

$LOAD_PATH << EmailAlertService.config.app_root
$LOAD_PATH << EmailAlertService.config.app_root + "email_alert_service"

Dir[File.join(EmailAlertService.config.app_root, "email_alert_service/**/*.rb")].each { |f| require f }

require "bundler/setup"
Bundler.require(:default, EmailAlertService.config.environment)

EmailAlertService.config.logger.level = Logger::DEBUG

Dir[File.join(EmailAlertService.config.app_root, "config/initializers/**/*.rb")].each { |f| require f }
