require "gds_api/email_alert_api"
require "models/lock_handler"

class EmailAlertWorker
  include Sidekiq::Worker

  def perform(formatted_email)
    lock_handler = LockHandler.new(formatted_email)

    if lock_handler.validate_and_set_lock
      email_api_client.send_alert(formatted_email)
    end
  end

private

  def email_api_client
    GdsApi::EmailAlertApi.new(Plek.find("email-alert-api"))
  end
end
