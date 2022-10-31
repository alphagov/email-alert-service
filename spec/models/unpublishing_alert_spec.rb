require "spec_helper"
require "lib/uuid_v5"

RSpec.describe UnpublishingAlert do
  include LockHandlerTestHelpers
  let(:content_id) { SecureRandom.uuid }
  let(:govuk_request_id) { "govuk_request_id" }
  let(:time) { Time.now }
  let(:public_updated_at) { time.iso8601 }
  let(:sender_message_id) { UUIDv5.call(content_id, public_updated_at) }
  let(:formatted_time) { time.strftime(UnpublishingMessagePresenter::EMAIL_DATE_FORMAT) }

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

  let(:fake_lock_handler_class) do
    Class.new do
      def with_lock_unless_done
        yield
      end
    end
  end

  let(:logger) { double(:logger, info: nil) }
  let(:unpublishing_alert) { UnpublishingAlert.new(document, logger, unpublishing_scenario) }
  let(:fake_lock_handler) { fake_lock_handler_class.new }
  let(:subscriber_list_slug) { "i_am_a_subscriber_list_slug" }

  before :each do
    allow(LockHandler).to receive(:new).and_return(fake_lock_handler)
  end

  describe "#trigger" do
    shared_examples "a request to bulk unsubscribe with appropriate logging" do
      it "logs that the list does not exist and does not make a request to bulk-unsubscribe" do
        stub_email_alert_api_does_not_have_subscriber_list("content_id" => content_id)

        unpublishing_alert.trigger

        expect(logger).to have_received(:info).with(
          "subscriber list not found for content id #{document['content_id']}",
        )
      end

      context "when the list exists" do
        before do
          stub_email_alert_api_has_subscriber_list(
            "content_id" => content_id,
            "slug" => subscriber_list_slug,
            "description" => "A subscriber list description.",
          )
        end

        it "logs an unsubscription notification" do
          stub_email_alert_api_bulk_unsubscribe(slug: subscriber_list_slug)

          unpublishing_alert.trigger

          expect(logger).to have_received(:info).with(
            "Received unsubscription notification for #{document['base_path']}, unpublishing_scenario: #{unpublishing_scenario}, full payload: #{document}",
          )
        end

        it "sends a bulk unsubscribe request to the Email Alert API" do
          stub = stub_email_alert_api_bulk_unsubscribe_with_message(
            slug: subscriber_list_slug,
            govuk_request_id:,
            body: email_markdown.strip,
            sender_message_id:,
          )

          unpublishing_alert.trigger

          expect(stub).to have_been_made
        end

        it "logs if it receives a conflict" do
          stub_email_alert_api_bulk_unsubscribe_conflict(slug: subscriber_list_slug)

          unpublishing_alert.trigger

          expect(logger).to have_received(:info).with(
            "email-alert-api returned conflict for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}",
          )
        end

        it "logs if it receives an unprocessable entity" do
          stub_email_alert_api_bulk_unsubscribe_bad_request(slug: subscriber_list_slug)

          unpublishing_alert.trigger

          expect(logger).to have_received(:info).with(
            "email-alert-api returned unprocessable entity for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}",
          )
        end

        it "logs if it receives not found" do
          stub_email_alert_api_bulk_unsubscribe_not_found(slug: subscriber_list_slug)

          unpublishing_alert.trigger

          expect(logger).to have_received(:info).with(
            "email-alert-api returned not_found for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}",
          )
        end
      end
    end

    describe "by published_in_error_with_url event" do
      let(:unpublishing_scenario) { :published_in_error_with_url }
      let(:alternative_path) { "/foo/alternative" }
      let(:document) { published_in_error_payload }
      let(:email_markdown) do
        <<~UNPUBLISHING_MESSAGE
          Page summary:
          A subscriber list description.

          Change made:
          This page was removed from GOV.UK because it was published in error. It’s been replaced by: https://www.test.gov.uk/foo/alternative

          Time updated:
          #{formatted_time}

          ^You’ve been automatically unsubscribed from this page because it was removed.
        UNPUBLISHING_MESSAGE
      end

      it_behaves_like "a request to bulk unsubscribe with appropriate logging"
    end

    describe "by published_in_error_without_url event" do
      let(:unpublishing_scenario) { :published_in_error_without_url }
      let(:alternative_path) { "" }
      let(:document) { published_in_error_payload }
      let(:email_markdown) do
        <<~UNPUBLISHING_MESSAGE
          Page summary:
          A subscriber list description.

          Change made:
          This page was removed from GOV.UK because it was published in error.

          Time updated:
          #{formatted_time}

          ^You’ve been automatically unsubscribed from this page because it was removed.
        UNPUBLISHING_MESSAGE
      end

      it_behaves_like "a request to bulk unsubscribe with appropriate logging"
    end

    describe "by consolidated event" do
      let(:unpublishing_scenario) { :consolidated }
      let(:document) { consolidated_payload }
      let(:email_markdown) do
        <<~UNPUBLISHING_MESSAGE
          Page summary:
          A subscriber list description.

          Change made:
          This page was removed from GOV.UK. It’s been replaced by https://www.test.gov.uk/government/publications/foobar

          Time updated:
          #{formatted_time}

          ^You’ve been automatically unsubscribed from this page because it was removed.
        UNPUBLISHING_MESSAGE
      end

      it_behaves_like "a request to bulk unsubscribe with appropriate logging"
    end
  end
end
