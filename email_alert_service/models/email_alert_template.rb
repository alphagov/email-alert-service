class EmailAlertTemplate
  def initialize(document)
    @document = document
  end

  def message_body
    %Q(
      <div class="rss_item" data-message-id="#{document_identifier_hash}" style="margin-bottom: 2em;">
        <div class="rss_title" style="font-size: 120%; margin: 0 0 0.3em; padding: 0;">
          <a href="#{make_url_from_document_base_path}" style="font-weight: bold; ">#{@document["title"]}</a>
        </div>
        #{formatted_public_updated_at}
        #{@document["details"]["change_note"]}
        <br />
        <div class="rss_description" style="margin: 0 0 0.3em; padding: 0;">#{@document["description"]}</div>
      </div>
    )
  end

private

  def make_url_from_document_base_path
    Plek.new.website_root + @document["base_path"]
  end

  def formatted_public_updated_at
    DateTime.parse(@document["public_updated_at"]).strftime("%l:%M%P, %-d %B %Y")
  end

  def document_identifier_hash
    MessageIdentifier.new(@document["title"], @document["public_updated_at"]).create
  end
end
