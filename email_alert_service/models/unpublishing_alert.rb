require "gds_api/email_alert_api"
require "lib/uuid_v5"
require "lib/email_alert_api_helpers"

class UnpublishingAlert
  include EmailAlertApiHelpers

  def initialize(document, logger, unpublishing_scenario)
    @document = document
    @logger = logger
    @unpublishing_scenario = unpublishing_scenario
  end

  def trigger
    logger.info "Received unsubscription notification for #{document['base_path']}, unpublishing_scenario: #{unpublishing_scenario}, full payload: #{document}"
    get_subscriber_list
    bulk_unsubscribe if subscriber_list_slug
  end

private

  attr_reader :document, :logger, :unpublishing_scenario, :content_item, :subscriber_list, :subscriber_list_slug, :page_title

  def bulk_unsubscribe
    lock_handler.with_lock_unless_done do
      Services.email_api_client.bulk_unsubscribe(
        slug: subscriber_list_slug,
        govuk_request_id: document["govuk_request_id"],
        body: unpublishing_message,
        sender_message_id: sender_message_id(document),
      )
    rescue GdsApi::HTTPConflict
      logger.info "email-alert-api returned conflict for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    rescue GdsApi::HTTPUnprocessableEntity
      logger.info "email-alert-api returned unprocessable entity for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    rescue GdsApi::HTTPNotFound
      logger.info "email-alert-api returned not_found for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    end
  end

  def unpublishing_message
    UnpublishingMessagePresenter.new(unpublishing_scenario, document, subscriber_list).call
  end

  def lock_handler
    LockHandler.new(document.fetch("content_id"), document.fetch("public_updated_at"))
  end

  def sender_message_id(document)
    UUIDv5.call(
      document.fetch("content_id"),
      document.fetch("public_updated_at"),
    )
  end
end
