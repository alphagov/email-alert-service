require_relative('./message_processor')

class MajorChangeMessageProcessor < MessageProcessor
protected # rubocop:disable Layout/IndentationWidth

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

  def trigger_email_alert(document)
    EmailAlert.new(document, @logger).trigger
  end

  def email_alerts_supported?(document)
    blacklisted = blacklisted_publishing_app?(document["publishing_app"]) \
      || blacklisted_document_type?(document["document_type"])
    return false if blacklisted

    document_tags = document.fetch("details", {}).fetch("tags", {})
    document_links = document.fetch("links", {})
    document_type = document.fetch("document_type")

    contains_supported_attribute?(document_links) \
      || contains_supported_attribute?(document_tags) \
      || whitelisted_document_type?(document_type) \
      || has_relevant_document_supertype?(document)
  end

  def contains_supported_attribute?(tags_hash)
    # These are attributes in links or tags which email subscriptions can be
    # based on.

    # We also send emails based on links to organisations, but don't include
    # organisations in this list because that would trigger emails for many
    # things which aren't appropriate. has_relevant_document_supertype? will
    # let through anything for which Whitehall would have sent emails to
    # organisation-based lists if none of these other attributes exist on it.
    supported_attributes = %w(
      topics
      policies
      service_manual_topics
      taxons
      world_locations
      topical_events
      people
      policy_areas
      roles
    )

    supported_attributes.any? do |tag_name|
      tags_hash[tag_name] && tags_hash[tag_name].any?
    end
  end

  def blacklisted_publishing_app?(publishing_app)
    # These publishing apps make direct calls to email-alert-api to send their
    # emails, so we need to avoid sending duplicate emails when they come
    # through on the queue:
    return true if %w(travel-advice-publisher specialist-publisher).include?(publishing_app)

    # These publishing apps don't manage any content where it would make sense to
    # subscribe to email updates for
    return true if %w(collections-publisher).include?(publishing_app)

    false
  end

  def blacklisted_document_type?(document_type)
    # These are documents that don't make sense to email someone about as they
    # are not useful to an end user.
    %w[coming_soon special_route].include?(document_type)
  end

  def whitelisted_document_type?(document_type)
    # It's possible to subscribe to these without any other filtering, so we
    # should always let them through
    document_type == "service_manual_guide"
  end

  def has_relevant_document_supertype?(document)
    relevant_supertype = ->(supertype) { !['other', '', nil].include?(supertype) }

    # These supertypes were added to Whitehall content to aid the migration of
    # Whitehall subscriptions to email-alert-api. We'd like to get to the point
    # where email subscriptions cover all content on the site rather than
    # perpetuating the Whitehall/everything else divide, but don't have time to
    # work through all the ramifications of that while also doing that migration
    # so are limiting the scope of emails to approximately what Whitehall did.
    relevant_supertype.call(document["government_document_supertype"]) ||
      relevant_supertype.call(document["email_document_supertype"])
  end

  def is_english?(document)
    # A missing locale is assumed to be English, but a "null" locale is not
    return true unless document.key?("locale")

    document["locale"] == "en"
  end

  def has_base_path?(document)
    has_non_blank_value_for_key?(document: document, key: "base_path")
  end

  def has_title?(document)
    has_non_blank_value_for_key?(document: document, key: "title")
  end

  def has_public_updated_at?(document)
    has_non_blank_value_for_key?(document: document, key: "public_updated_at")
  end

  def has_change_note?(document)
    note = ChangeHistory.new(
      history: document.dig("details", "change_history")
    ).latest_change_note

    !note.nil? && !note.empty?
  end

  def has_non_blank_value_for_key?(document:, key:)
    # a key can be present but the value is nil, so fetch won't
    # protect us here
    return false unless document.key?(key)

    (document[key] || "") != ""
  end
end
