class EmailAlert
  def initialize(document, logger, worker)
    @document = document
    @logger = logger
    @worker = worker
  end

  def trigger
    @logger.info "Received major change notification for #{document["title"]}, with topics #{document["details"]["tags"]["topics"]}"
    @worker.perform_async(format_for_email_api)
  end

  def format_for_email_api
    {
      "subject" => document["title"],
      "body" => format_email_body,
      "tags" => strip_empty_arrays(document["details"]["tags"]),
    }
  end

private

  attr_reader :document

  def format_email_body
    %Q( <div class="rss_item" style="margin-bottom: 2em;">
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
    Plek.new.website_root
  end

  def strip_empty_arrays(tag_hash)
    tag_hash.reject {|_, tags|
      tags.empty?
    }
  end

  def formatted_public_updated_at
    DateTime.parse(document["public_updated_at"]).strftime("%I:%M%P, %-d %B %Y")
  end
end
