require "gds_api/email_alert_api"
require "models/lock_handler"
require  "gds_api/content_store"

class EmailAlert
  def initialize(document, logger)
    @document = document
    @logger = logger
    @content_store = GdsApi::ContentStore.new(Plek.new.find('content-store'))
  end

  def trigger
    logger.info "Received major change notification for #{document["title"]}, with topics #{document["details"]["tags"]["topics"]}"

    lock_handler.with_lock_unless_done do
      email_api_client.send_alert(format_for_email_api)
    end
  end

  def format_for_email_api
    {
    api_params = {
      "subject" => document["title"],
      "body" => format_email_body,
      "tags" => strip_empty_arrays(document["details"]["tags"]),
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

  def format_email_body
    %Q( <div class="rss_item" data-message-id="#{document_identifier_hash}" style="margin-bottom: 2em;">
          <div class="rss_title" style="font-size: 120%; margin: 0 0 0.3em; padding: 0;">
            <a href="#{make_url_from_document_base_path}" style="font-weight: bold; ">#{document["title"]}</a>
          </div>
          #{formatted_public_updated_at}
          #{document["details"]["change_note"]}
          <br />
          <div class="rss_description" style="margin: 0 0 0.3em; padding: 0;">#{document["description"]}</div>
        </div> )
  end

  def make_url_from_document_base_path
    base_path = document["base_path"]
    content_item = @content_store.content_item(base_path)
    link = content_item.links.parent[0].web_url
  end

  def strip_empty_arrays(tag_hash)
    tag_hash.reject {|_, tags|
      tags.empty?
    }
  end

  def formatted_public_updated_at
    DateTime.parse(document["public_updated_at"]).strftime("%l:%M%P, %-d %B %Y")
  end

  def document_identifier_hash
    MessageIdentifier.new(document["title"], document["public_updated_at"]).create
  end
end
