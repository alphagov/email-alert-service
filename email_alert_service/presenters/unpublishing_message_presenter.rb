require "active_support/core_ext/object/blank"

class UnpublishingMessagePresenter
  EMAIL_DATE_FORMAT = "%l:%M%P, %-d %B %Y".freeze

  def initialize(unpublishing_scenario, document, subscriber_list)
    @unpublishing_scenario = unpublishing_scenario
    @document = document
    @subscriber_list = subscriber_list
  end

  def call
    [
      page_summary,
      ["Change made:\n", unpublishing_scenario_note].join,
      ["Time updated:\n", formatted_time].join,
      "^You’ve been automatically unsubscribed from this page because it was removed.",
    ].compact.join("\n\n")
  end

private

  attr_reader :unpublishing_scenario, :document, :subscriber_list

  def formatted_time
    Time.iso8601(document["public_updated_at"]).strftime(EMAIL_DATE_FORMAT)
  end

  def unpublishing_scenario_note
    case unpublishing_scenario
    when :consolidated
      "This page was removed from GOV.UK. It’s been replaced by #{url_for(base_path: document['redirects'][0]['destination'])}"
    when :published_in_error_with_url
      "This page was removed from GOV.UK because it was published in error. It’s been replaced by: #{url_for(base_path: document['details']['alternative_path'])}"
    when :published_in_error_without_url
      "This page was removed from GOV.UK because it was published in error."
    end
  end

  def website_root
    Plek.new.website_root
  end

  def default_utm_params
    { utm_medium: "email", utm_campaign: "govuk-notifications" }
  end

  def url_for(base_path:, **params)
    uri = URI.join(website_root, base_path)
    query = Hash[URI.decode_www_form(uri.query.to_s)]

    query = query.merge(default_utm_params) if params.key?(:utm_source)
    query = query.merge(params).compact

    uri.query = URI.encode_www_form(query).presence
    uri.to_s
  end

  def page_summary
    description = subscriber_list["description"]
    if description.nil? || description.empty?
      GovukError.notify("Recieved unpublishing message with empty or missing description for subscriber list ID: #{subscriber_list['id']}")
      return nil
    end

    ["Page summary:\n", description].join
  end
end
