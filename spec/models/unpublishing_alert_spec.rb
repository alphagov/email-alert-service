require "spec_helper"
require "lib/uuid_v5"

RSpec.describe UnpublishingAlert do
  include LockHandlerTestHelpers
  let(:content_id) { SecureRandom.uuid }
  let(:govuk_request_id) { SecureRandom.uuid }
  let(:public_updated_at) { updated_now.iso8601 }
  let(:sender_message_id) { UUIDv5.call(content_id, public_updated_at) }
  let(:formatted_time) { Time.new(public_updated_at).strftime(UnpublishingMessagePresenter::EMAIL_DATE_FORMAT) }

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
  let(:subscriber_list_uuid) { SecureRandom.uuid }
  let(:subscriber_list_response) do
    {
      "subscriber_list" => {
        "id" => subscriber_list_uuid,
        "title" => "Subscriber List Title",
      },
    }
  end
  let(:alert_api) { double(:alert_api, bulk_unsubscribe: nil, find_subscriber_list: subscriber_list_response) }

  before :each do
    allow(LockHandler).to receive(:new).and_return(fake_lock_handler)
    allow(Services).to receive(:email_api_client).and_return(alert_api)
  end

  describe "#trigger" do
    shared_examples "a request to bulk unsubscribe with appropriate logging" do
      it "logs an unsubscription notification" do
        unpublishing_alert.trigger

        expect(logger).to have_received(:info).with(
          "Received unsubscription notification for #{document['title']}, unpublishing_scenario: #{unpublishing_scenario}, full payload: #{document}",
        )
      end

      it "sends a bulk unsubscribe request to the Email Alert API" do
        unpublishing_alert.trigger

        expect(alert_api).to have_received(:bulk_unsubscribe).with(
          {
            "subscriber_list_id" => subscriber_list_uuid,
            "body" => email_markdown.strip,
            "sender_message_id" => sender_message_id,
          }.to_json,
        )
      end

      it "logs if it recieves a conflict" do
        allow(alert_api).to receive(:bulk_unsubscribe).and_raise(GdsApi::HTTPConflict.new(409))
        unpublishing_alert.trigger

        expect(logger).to have_received(:info).with(
          "email-alert-api returned conflict for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}",
        )
      end

      it "logs if it recieves an unprocessable entity" do
        allow(alert_api).to receive(:bulk_unsubscribe).and_raise(GdsApi::HTTPUnprocessableEntity.new(422))
        unpublishing_alert.trigger

        expect(logger).to have_received(:info).with(
          "email-alert-api returned unprocessable entity for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}",
        )
      end

      it "logs if it recieves not found" do
        allow(alert_api).to receive(:bulk_unsubscribe).and_raise(GdsApi::HTTPNotFound.new(404))
        unpublishing_alert.trigger

        expect(logger).to have_received(:info).with(
          "email-alert-api returned not_found for #{document['content_id']}, #{document['base_path']}, #{document['public_updated_at']}",
        )
      end
    end

    describe "by published_in_error_with_url event" do
      let(:unpublishing_scenario) { :published_in_error_with_url }
      let(:alternative_path) { "/foo/alternative" }
      let(:document) { published_in_error_payload }
      let(:email_markdown) do
        <<~UNPUBLISHING_MESSAGE
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
