require "gds_api/email_alert_api"
require "models/lock_handler"
require "models/email_alert_template"

class EmailAlert
  def initialize(document, logger)
    @document = document
    @logger = logger
  end

  def trigger
    logger.info "Received major change notification for #{document["title"]}, with topics #{document["details"]["tags"]["topics"]}"

    lock_handler.with_lock_unless_done do
      email_api_client.send_alert(format_for_email_api)
    end
  end

  def format_for_email_api
    api_params = {
      "subject" => document["title"],
      "body"    => EmailAlertTemplate.new(document).message_body,
      "tags"    => strip_empty_arrays(document["details"]["tags"]),
    }

    # FIXME: this conditional check on links should be considered temporary.
    # Eventually we want all email alerts to be triggered via content IDs received
    # in the expected form below. The 'tags' hash will then be deprecated.
    # Rework this method when that happens.
    if document["links"] && document["links"]["parent"]
      api_params.merge!({"links" => document["links"]})
    end

    api_params
  end

private

  attr_reader :document, :logger

  def lock_handler
    LockHandler.new(document.fetch("title"), document.fetch("public_updated_at"))
  end

  def email_api_client
    GdsApi::EmailAlertApi.new(Plek.find("email-alert-api"))
  end

  def strip_empty_arrays(tag_hash)
    tag_hash.reject { |_, tags| tags.empty? }
  end
end
