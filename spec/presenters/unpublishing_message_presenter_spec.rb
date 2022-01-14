require "spec_helper"

RSpec.describe UnpublishingMessagePresenter do
  let(:content_id) { SecureRandom.uuid }
  let(:govuk_request_id) { SecureRandom.uuid }
  let(:public_updated_at) { Time.now.iso8601 }
  let(:formatted_time) { Time.new(public_updated_at).strftime(UnpublishingMessagePresenter::EMAIL_DATE_FORMAT) }
  let(:alternative_path) { nil }
  let(:website_domain) { "https://www.test.gov.uk" }
  let(:presenter) { UnpublishingMessagePresenter.new(unpublishing_scenario, document) }

  let(:published_in_error_payload) do
    {
      "document_type" => "gone",
      "schema_name" => "gone",
      "base_path" => "/foo",
      "locale" => "en",
      "publishing_app" => "whitehall",
      "public_updated_at" => public_updated_at,
      "details" => {
        "explanation" => "Why the page was published in error",
        "alternative_path" => alternative_path,
      },
      "content_id" => content_id,
      "govuk_request_id" => govuk_request_id,
      "payload_version" => 199,
    }
  end

  let(:consolidated_payload) do
    {
      "document_type" => "redirect",
      "schema_name" => "redirect",
      "base_path" => "/foo",
      "locale" => "en",
      "publishing_app" => "whitehall",
      "redirects" => [
        {
          "path" => "/government/publications/foo/html-attachment-foo",
          "type" => "exact",
          "destination" => "/government/publications/foobar",
        },
      ],
      "public_updated_at" => public_updated_at,
      "content_id" => content_id,
      "govuk_request_id" => govuk_request_id,
      "payload_version" => 199,
    }
  end

  describe "#call" do
    context "presenting a consolidated event" do
      let(:unpublishing_scenario) { :consolidated }
      let(:document) { consolidated_payload }

      it "presents markdown for an email" do
        expected_markdown = <<~UNPUBLISHING_MESSAGE
          Change made:
          This page was removed from GOV.UK. It’s been replaced by #{website_domain}/government/publications/foobar

          Time updated:
          #{formatted_time}

          ^You’ve been automatically unsubscribed from this page because it was removed.
        UNPUBLISHING_MESSAGE

        expect(presenter.call).to eq(expected_markdown.strip)
      end
    end

    context "presenting a published_in_error_with_url event" do
      let(:unpublishing_scenario) { :published_in_error_with_url }
      let(:alternative_path) { "/foo/alternative" }
      let(:document) { published_in_error_payload }

      it "presents markdown for an email" do
        expected_markdown = <<~UNPUBLISHING_MESSAGE
          Change made:
          This page was removed from GOV.UK because it was published in error. It’s been replaced by: #{website_domain}/foo/alternative

          Time updated:
          #{formatted_time}

          ^You’ve been automatically unsubscribed from this page because it was removed.
        UNPUBLISHING_MESSAGE
        expect(presenter.call).to eq(expected_markdown.strip)
      end
    end

    context "presenting a published_in_error_without_url event" do
      let(:unpublishing_scenario) { :published_in_error_without_url }
      let(:document) { published_in_error_payload }

      it "presents markdown for an email" do
        expected_markdown = <<~UNPUBLISHING_MESSAGE
          Change made:
          This page was removed from GOV.UK because it was published in error.

          Time updated:
          #{formatted_time}

          ^You’ve been automatically unsubscribed from this page because it was removed.
        UNPUBLISHING_MESSAGE

        expect(presenter.call).to eq(expected_markdown.strip)
      end
    end
  end
end
