require_relative "../email_alert_service/config"

module EmailAlertService
  def self.config
    EmailAlertService::Config.new(ENV["GOVUK_ENV"])
  end
end

[
  EmailAlertService.config.app_root,
  EmailAlertService.config.app_root + "email_alert_service"
].each do |path|
  $LOAD_PATH << path.to_s
end

require "bundler/setup"
Bundler.require(:default, EmailAlertService.config.environment)

require "govuk_app_config"

EmailAlertService.config.logger.level = Logger::DEBUG

Dir.glob('email_alert_service/models/*.rb').each { |r| require r }

Dir[File.join(EmailAlertService.config.app_root, "config/initializers/**/*.rb")].each { |f| require f }
