require_relative("./message_processor")

class MajorChangeMessageProcessor < MessageProcessor
protected

  def process_message(message)
    document = message.payload
    unless has_base_path?(document)
      @logger.info "not triggering email alert for document with no base_path: #{document}"
      return
    end

    unless has_title?(document)
      @logger.info "not triggering email alert for document with no title: #{document}"
      return
    end

    unless has_public_updated_at?(document)
      @logger.info "not triggering email alert for document with no public_updated_at: #{document}"
      return
    end

    unless is_english?(document)
      @logger.info "not triggering email alert for non-english document #{document['title']}: locale #{document['locale']}"
      return
    end

    unless has_change_note?(document)
      @logger.info "not triggering email alert for document missing change note #{document}"
      return
    end

    if email_alerts_supported?(document)
      @logger.info "triggering email alert for document #{document['title']}"
      trigger_email_alert(document)
    end
  end

private

  def trigger_email_alert(document)
    EmailAlert.new(document, @logger).trigger
  end

  def email_alerts_supported?(document)
    return false if blocked_publishing_app?(document["publishing_app"]) ||
      blocked_document_type?(document["document_type"])

    document_tags = document.fetch("details", {}).fetch("tags", {})
    document_links = document.fetch("links", {})

    contains_supported_attribute?(document_links) ||
      contains_supported_attribute?(document_tags) ||
      links_to_singleton_page?(document_links) ||
      has_relevant_document_supertype?(document)
  end

  def contains_supported_attribute?(tags_hash)
    # These are attributes in links or tags which email subscriptions can be
    # based on.

    # We also send emails based on links to organisations, but don't include
    # organisations in this list because that would trigger emails for many
    # things which aren't appropriate. has_relevant_document_supertype? will
    # let through anything for which Whitehall would have sent emails to
    # organisation-based lists if none of these other attributes exist on it.
    supported_attributes = %w[
      policies
      service_manual_topics
      taxons
      world_locations
      topical_events
      people
      policy_areas
      roles
    ]

    supported_attributes.any? do |tag_name|
      tags_hash[tag_name] && tags_hash[tag_name].any?
    end
  end

  def blocked_publishing_app?(publishing_app)
    # These publishing apps make direct calls to email-alert-api to send their
    # emails, so we need to avoid sending duplicate emails when they come
    # through on the queue:
    return true if %w[travel-advice-publisher specialist-publisher].include?(publishing_app)

    # These publishing apps don't manage any content where it would make sense to
    # subscribe to email updates for
    return true if %w[collections-publisher].include?(publishing_app)

    false
  end

  def blocked_document_type?(document_type)
    # These are documents that don't make sense to email someone about as they
    # are not useful to an end user.
    %w[coming_soon special_route].include?(document_type)
  end

  def links_to_singleton_page?(document_links)
    # These documents link to the single-instance of service_manual_service_standard
    document_links["parent"] == %w[00f693d4-866a-4fe6-a8d6-09cd7db8980b]
  end

  def has_relevant_document_supertype?(document)
    relevant_supertype = ->(supertype) { !["other", "", nil].include?(supertype) }

    # These supertypes were added to Whitehall content to aid the migration of
    # Whitehall subscriptions to email-alert-api. We'd like to get to the point
    # where email subscriptions cover all content on the site rather than
    # perpetuating the Whitehall/everything else divide, but don't have time to
    # work through all the ramifications of that while also doing that migration
    # so are limiting the scope of emails to approximately what Whitehall did.
    relevant_supertype.call(document["government_document_supertype"]) ||
      relevant_supertype.call(document["email_document_supertype"])
  end

  def has_change_note?(document)
    note = ChangeHistory.new(
      history: document.dig("details", "change_history"),
    ).latest_change_note

    !note.nil? && !note.empty?
  end
end
