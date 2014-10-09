require "gds_api/email_alert_api"

class EmailAlertWorker
  include Sidekiq::Worker

  def perform(formatted_alert)
    email_api_client.send_alert(formatted_alert)
  end

private

  def email_api_client
    GdsApi::EmailAlertApi.new(Plek.find("email-alert-api"))
  end
end
