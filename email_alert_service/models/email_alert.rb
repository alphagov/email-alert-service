require "gds_api/email_alert_api"
require "models/lock_handler"
require "models/email_alert_template"
require "govuk_taxonomy_helpers"

class EmailAlert
  def initialize(document, logger)
    @document = document
    @logger = logger
  end

  def trigger
    logger.info "Received major change notification for #{document["title"]}, with details #{document["details"]}"
    lock_handler.with_lock_unless_done do
      email_api_client.send_alert(format_for_email_api, govuk_request_id: document['govuk_request_id'])
    end
  end

  def format_for_email_api
    {
      "subject" => document["title"],
      "body" => EmailAlertTemplate.new(document).message_body,
      "tags" => strip_empty_arrays(document.fetch("details", {}).fetch("tags", {})),
      "links" => document_links,
      "document_type" => document["document_type"],
      "content_id" => document["content_id"],
      "public_updated_at" => document["public_updated_at"],
      "publishing_app" => document["publishing_app"],
    }
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

  def document_links
    strip_empty_arrays(
      document.fetch("links", {}).merge("taxon_tree" => taxon_tree)
    )
  end

  def taxon_tree
    return [] unless document.dig("links", "taxons")

    # TODO: update the public API of the taxonomy helpers gem to also accept a
    # single fully expanded document so that we don't have to pass in the
    # document twice.
    linked_content_item = GovukTaxonomyHelpers::LinkedContentItem.from_publishing_api(
      content_item: document,
      expanded_links: document,
    )

    linked_content_item.taxons_with_ancestors.map(&:content_id).uniq
  end
end
