module EmailAlertApiHelpers
  def get_subscriber_list
    @subscriber_list = Services.email_api_client.find_subscriber_list(content_id: document.fetch("content_id"))
                                               .to_h.fetch("subscriber_list")
    @subscriber_list_slug = @subscriber_list.fetch("slug")
  rescue GdsApi::HTTPNotFound
    logger.info "subscriber list not found for content id #{document['content_id']}"
  end
end
