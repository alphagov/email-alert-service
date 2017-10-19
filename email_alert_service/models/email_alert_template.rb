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
        #{latest_change_note}
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
    # This returns the local time in London since that's what users expect to see
    # rather than UTC
    timezone = TZInfo::Timezone.get('Europe/London')
    timezone.utc_to_local(DateTime.parse(@document["public_updated_at"])).strftime("%l:%M%P, %-d %B %Y")
  end

  def latest_change_note
    change_note = @document["details"]["change_history"]&.first
    change_note["note"] if change_note
  end

  def document_identifier_hash
    MessageIdentifier.new(@document["title"], @document["public_updated_at"]).create
  end
end
