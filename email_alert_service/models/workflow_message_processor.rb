require_relative('./message_processor')
require_relative('./message_processor_validator')

class WorkflowMessageProcessor < MessageProcessor
  include MessageProcessorValidator

  WHITELISTED_PUBLISHING_APPS = %w[content-tagger].freeze

protected

  def process_message(message)
    document = message.parsed_document

    if valid_message?(document) && email_alerts_supported?(document)
      @logger.info "triggering email alert for document #{document['title']}"
      trigger_email_alert(document)
    end
  end

  def trigger_email_alert(document)
    EmailAlert.new(document, @logger).trigger
  end

  def email_alerts_supported?(document)
    whitelisted_publishing_app?(document["publishing_app"]) &&
      valid_workflow?(document)
  end

  def whitelisted_publishing_app?(publishing_app)
    return true if WHITELISTED_PUBLISHING_APPS.include?(publishing_app)

    false
  end

  def valid_message?(document)
    unless has_workflow_message?(document)
      @logger.info "not triggering email alert for document with no workflow message"

      return false
    end

    valid?(document)
  end

  def has_workflow_message?(document)
    has_non_blank_value_for_key?(document: document, key: "workflow_message")
  end

  # Tagging documents with facets is (currently) the only workflow permitted
  # for generating notifications.
  def valid_workflow?(document)
    document_links = document.fetch("links", {})
    document_links.fetch("facet_groups", []).any? &&
      document_links.fetch("facet_values", []).any?
  end
end
