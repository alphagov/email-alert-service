require "gds_api/email_alert_api"
require "lib/uuid_v5"

class UnpublishingAlert
  def initialize(document, logger, unpublishing_scenario)
    @document = document
    @logger = logger
    @unpublishing_scenario = unpublishing_scenario
  end

  def trigger
    logger.info "Received unsubscription notification for #{document['title']}, unpublishing_scenario: #{unpublishing_scenario}, full payload: #{document}"
    get_subscriber_list
    bulk_unsubscribe if subscriber_list_id
  end

private

  attr_reader :document, :logger, :unpublishing_scenario, :content_item, :subscriber_list, :subscriber_list_id, :page_title

  def bulk_unsubscribe
    lock_handler.with_lock_unless_done do
      Services.email_api_client.bulk_unsubscribe(
        {
          subscriber_list_id: subscriber_list_id,
          body: unpublishing_message,
          sender_message_id: sender_message_id(document),
        }.to_json,
      )
    rescue GdsApi::HTTPConflict
      logger.info "email-alert-api returned conflict for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    rescue GdsApi::HTTPUnprocessableEntity
      logger.info "email-alert-api returned unprocessable entity for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    rescue GdsApi::HTTPNotFound
      logger.info "email-alert-api returned not_found for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    end
  end

  def get_subscriber_list
    @subscriber_list = Services.email_api_client.find_subscriber_list(content_id: document.fetch("content_id"))
    @subscriber_list_id = @subscriber_list.to_h.fetch("subscriber_list").fetch("id")
  rescue GdsApi::HTTPNotFound
    logger.info "subscriber list not found for content id #{document['content_id']}"
    nil
  end

  def unpublishing_message
    UnpublishingMessagePresenter.new(unpublishing_scenario, document).call
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
