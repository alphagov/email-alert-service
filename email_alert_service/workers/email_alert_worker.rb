require "gds_api/email_alert_api"
require "models/lock_handler"

class EmailAlertWorker
  include Sidekiq::Worker

  def perform(email)
    public_updated_at = email.fetch("public_updated_at")
    formatted_email = email.fetch("formatted")
    lock_handler = LockHandler.new(
      formatted_email.fetch("subject"),
      public_updated_at,
    )

    if lock_handler.validate_and_set_lock
      email_api_client.send_alert(formatted_email)
    end
  end

private

  def email_api_client
    GdsApi::EmailAlertApi.new(Plek.find("email-alert-api"))
  end
end
