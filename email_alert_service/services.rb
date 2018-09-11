module Services
  def self.email_api_client
    @email_api_client ||= GdsApi::EmailAlertApi.new(
      Plek.find("email-alert-api"),
      bearer_token: ENV.fetch("EMAIL_ALERT_API_BEARER_TOKEN", "email-alert-api-bearer-token")
    )
  end
end
