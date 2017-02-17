require "gds_api/email_alert_api"
require "models/lock_handler"
require "models/email_alert_template"

class EmailAlert
  def initialize(document, logger)
    @document = document
    @logger = logger
  end

  def trigger
    logger.info "Received major change notification for #{document["title"]}, with details #{document["details"]}"
    lock_handler.with_lock_unless_done do
      email_api_client.send_alert(format_for_email_api)
    end
  end

  def format_for_email_api
    {
      "subject" => document["title"],
      "body" => EmailAlertTemplate.new(document).message_body,
      "tags" => strip_empty_arrays(document.fetch("details", {}).fetch("tags", {})),
      "links" => strip_empty_arrays(document.fetch("links", {}).merge('taxons_tree' => taxon_tree)),
      "document_type" => document["document_type"]
    }
  end

private

  def taxon_tree
    node = document.fetch("expanded_links", {}).fetch('taxons', []).first
    return [] unless node
    [node['content_id']] + children_taxons(node)
  end

  def children_taxons(node)
    # binding.pry
    links_node = node.fetch("links", {})
    if links_node.key?("parent_taxons")
      parent_node = links_node["parent_taxons"].first
      [parent_node['content_id']] + children_taxons(parent_node)
    else
      []
    end
  end

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
end
