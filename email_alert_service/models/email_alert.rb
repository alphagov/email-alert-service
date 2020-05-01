require "gds_api/email_alert_api"

class EmailAlert
  HIGH_PRIORITY_DOCUMENT_TYPES = %w[travel_advice medical_safety_alert].freeze
  BLANK_DESCRIPTION_DOCUMENT_TYPES = %w[travel_advice].freeze

  def initialize(document, logger)
    @document = document
    @logger = logger
  end

  def trigger
    logger.info "Received major change notification for #{document['title']}, with details #{document['details']}"
    lock_handler.with_lock_unless_done do
      Services.email_api_client.create_content_change(format_for_email_api, govuk_request_id: document["govuk_request_id"])
    rescue GdsApi::HTTPConflict
      logger.info "email-alert-api returned conflict for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    rescue GdsApi::HTTPUnprocessableEntity
      logger.info "email-alert-api returned unprocessable entity for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}"
    end
  end

  def format_for_email_api
    {
      "title" => document["title"],
      "description" => description,
      "change_note" => change_note,
      "subject" => document["title"],
      "tags" => strip_empty_arrays(document.fetch("details", {}).fetch("tags", {})),
      "links" => document_links,
      "document_type" => document_type,
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
      history: document["details"]["change_history"],
    ).latest_change_note
  end

  def lock_handler
    LockHandler.new(document.fetch("title"), document.fetch("public_updated_at"))
  end

  def strip_empty_arrays(tag_hash)
    tag_hash.reject { |_, tags| tags.empty? }
  end

  def document_links
    strip_empty_arrays(
      document.fetch("links", {}).merge("taxon_tree" => taxon_tree),
    )
  end

  def taxon_tree
    TaxonTree.ancestors(document.dig("expanded_links", "taxons").to_a)
  end

  def document_type
    document.fetch("document_type")
  end

  def priority
    HIGH_PRIORITY_DOCUMENT_TYPES.include?(document_type) ? "high" : "normal"
  end

  def description
    return "" if BLANK_DESCRIPTION_DOCUMENT_TYPES.include?(document_type)

    document["description"]
  end
end
