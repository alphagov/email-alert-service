require "lib/email_alert_api_helpers"

class UpdateSubscriberList
  include EmailAlertApiHelpers

  def initialize(document, logger)
    @document = document
    @logger = logger
  end

  def trigger
    get_subscriber_list
    return unless subscriber_list_slug

    if parameters_need_updating?
      logger.info "Updating subscriber list: #{subscriber_list_slug}, with: #{updateable_parameters}"
      update_subscriber_list_details
    else
      logger.info "No update needed to subscriber list: #{subscriber_list_slug}"
    end
  end

private

  attr_reader :document, :logger, :subscriber_list, :subscriber_list_slug

  def update_subscriber_list_details
    Services.email_api_client.update_subscriber_list_details(
      slug: subscriber_list_slug,
      params: updateable_parameters,
    )
  rescue GdsApi::HTTPUnprocessableEntity
    logger.info "email-alert-api returned unproessable entity updating subscriber list: #{subscriber_list_slug}, with: #{updateable_parameters}"
  rescue GdsApi::HTTPNotFound
    logger.info "email-alert-api cannot find subscriber list with slug #{subscriber_list_slug}"
  end

  def updateable_parameters
    {
      "title" => document["title"],
    }
  end

  def parameters_need_updating?
    subscriber_list["title"] != document["title"]
  end
end
