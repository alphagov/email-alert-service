class UpdateSubscriberList
  def initialize(document, logger)
    @document = document
    @logger = logger
  end

  def trigger
    get_subscriber_list
    return unless subscriber_list_slug

    if updateable_parameters.empty?
      logger.info "Update cancelled for subscriber list: #{subscriber_list_slug}, no updatable paramters found"
      return
    end

    if paramaters_need_updating?
      logger.info "Attempting to update subscriber list: #{subscriber_list_slug}, with: #{updateable_parameters}"
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

  def get_subscriber_list
    @subscriber_list = Services.email_api_client.find_subscriber_list(content_id: document.fetch("content_id"))
                                               .to_h.fetch("subscriber_list")
    @subscriber_list_slug = @subscriber_list.fetch("slug")
  rescue GdsApi::HTTPNotFound
    logger.info "subscriber list not found for content id #{document['content_id']}"
  end

  def updateable_parameters
    {
      "title" => document["title"],
    }
  end

  def paramaters_need_updating?
    subscriber_list["title"] != document["title"]
  end
end
