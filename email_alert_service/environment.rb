require "bundler/setup"
require "bootsnap"
Bootsnap.setup(
  cache_dir: ENV.fetch("BOOTSNAP_CACHE_DIR", "tmp/cache"),
  development_mode: ENV["RACK_ENV"] == "development",
)

require_relative "../email_alert_service/config"

module EmailAlertService
  def self.config
    EmailAlertService::Config.new(ENV["GOVUK_ENV"])
  end
end

[
  EmailAlertService.config.app_root,
  "#{EmailAlertService.config.app_root}/email_alert_service",
].each do |path|
  $LOAD_PATH << path.to_s
end

Bundler.require(:default, EmailAlertService.config.environment)

require "govuk_app_config"

EmailAlertService.config.logger.level = Logger::DEBUG

Dir.glob("email_alert_service/**/*.rb").sort.each { |r| require r }

Dir[File.join(EmailAlertService.config.app_root, "config/initializers/**/*.rb")].sort.each { |f| require f }
