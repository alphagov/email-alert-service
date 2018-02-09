require "gds_api/email_alert_api"

class EmailAlert
  HIGH_PRIORITY_DOCUMENT_TYPES = %w(travel_advice medical_safety_alert).freeze

  def initialize(document, logger)
    @document = document
    @logger = logger
  end

  def trigger
    logger.info "Received major change notification for #{document['title']}, with details #{document['details']}"
    lock_handler.with_lock_unless_done do
      begin
        email_api_client.send_alert(format_for_email_api, govuk_request_id: document['govuk_request_id'])
      rescue GdsApi::HTTPConflict
        logger.info "email-alert-api returned conflict for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
      end
    end
  end

  def format_for_email_api
    {
      "title" => document["title"],
      "description" => document["description"],
      "change_note" => change_note,
      "subject" => document["title"],
      "body" => EmailAlertTemplate.new(document).message_body,
      "tags" => strip_empty_arrays(document.fetch("details", {}).fetch("tags", {})),
      "links" => document_links,
      "document_type" => document["document_type"],
      "email_document_supertype" => document["email_document_supertype"],
      "government_document_supertype" => document["government_document_supertype"],
      "content_id" => document["content_id"],
      "public_updated_at" => document["public_updated_at"],
      "publishing_app" => document["publishing_app"],
      "base_path" => document["base_path"],
      "priority" => priority,
    }
  end

private

  attr_reader :document, :logger

  def change_note
    ChangeHistory.new(
      history: document['details']['change_history']
    ).latest_change_note
  end

  def lock_handler
    LockHandler.new(document.fetch("title"), document.fetch("public_updated_at"))
  end

  def email_api_client
    GdsApi::EmailAlertApi.new(
      Plek.find("email-alert-api"),
      bearer_token: ENV.fetch("EMAIL_ALERT_API_BEARER_TOKEN", "email-alert-api-bearer-token")
    )
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
    TaxonTree.ancestors(document.dig("expanded_links", "taxons").to_a)
  end

  def priority
    HIGH_PRIORITY_DOCUMENT_TYPES.include?(document.fetch("document_type")) ? "high" : "normal"
  end
end
