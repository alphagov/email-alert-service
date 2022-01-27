require "spec_helper"

RSpec.describe UpdateSubscriberList do
  let(:content_id) { SecureRandom.uuid }
  let(:document_title) { "Example Title" }
  let(:document_description) { "Example description" }
  let(:document) do
    {
      "base_path" => "/foo",
      "content_id" => content_id,
      "title" => document_title,
      "update_type" => update_type,
      "description" => document_description,
    }
  end

  let(:logger) { double(:logger, info: nil) }
  let(:update_subscriber_list) { UpdateSubscriberList.new(document, logger) }
  let(:subscriber_list_slug) { "subscriber_list_slug" }
  let(:updateable_parameters) { { "title" => document_title, "description" => document_description } }

  let(:subscriber_list_attributes) do
    {
      "content_id" => content_id,
      "slug" => subscriber_list_slug,
      "title" => subscriber_list_title,
      "description" => subscriber_list_description,
    }
  end

  describe "#trigger" do
    shared_examples "an attempt to update subscriber lists with appropriate logging" do
      let(:subscriber_list_title) { "An old outdated title" }
      let(:subscriber_list_description) { document_description }

      context "subscriber list found by content id" do
        before { stub_email_alert_api_has_subscriber_list(subscriber_list_attributes) }

        it "logs an attempt to update the subscriber list and triggers the api to update the title" do
          stub_email_alert_api_has_subscriber_list(subscriber_list_attributes)
          stub_update_subscriber_list_details(slug: subscriber_list_slug, params: updateable_parameters)
          update_subscriber_list.trigger

          expect(logger).to have_received(:info).with(
            "Updating subscriber list: #{subscriber_list_slug}, with: #{updateable_parameters}",
          )
        end

        context "subscriber list title matches document list" do
          let(:subscriber_list_title) { document_title }

          it "logs the outcome and does not attempt an update request" do
            stub_update_subscriber_list_details(slug: subscriber_list_slug, params: updateable_parameters)
            update_subscriber_list.trigger

            expect(logger).to have_received(:info).with(
              "No update needed to subscriber list: #{subscriber_list_slug}",
            )
          end
        end

        context "subscriber list description doesn't match document" do
          let(:subscriber_list_description) { "An old description" }

          it "logs an update to the subscriber list and triggers the api to update the title and description" do
            stub_email_alert_api_has_subscriber_list(subscriber_list_attributes)
            stub_update_subscriber_list_details(slug: subscriber_list_slug, params: updateable_parameters)
            update_subscriber_list.trigger

            expect(logger).to have_received(:info).with(
              "Updating subscriber list: #{subscriber_list_slug}, with: #{updateable_parameters}",
            )
          end
        end

        context "update attempted with invalid parameters" do
          let(:document_title) { "" }

          before { stub_update_subscriber_list_details_unprocessible_entity(slug: subscriber_list_slug, params: updateable_parameters) }

          it "logs the outcome" do
            update_subscriber_list.trigger

            expect(logger).to have_received(:info).with(
              "email-alert-api returned unproessable entity updating subscriber list: #{subscriber_list_slug}, with: #{updateable_parameters}",
            )
          end
        end

        context "subscriber list cannot be found to update by slug" do
          before { stub_update_subscriber_list_details_not_found(slug: subscriber_list_slug, params: updateable_parameters) }

          it "logs the outcome" do
            update_subscriber_list.trigger

            expect(logger).to have_received(:info).with(
              "email-alert-api cannot find subscriber list with slug #{subscriber_list_slug}",
            )
          end
        end
      end

      context "subscriber list cannot be found by content id" do
        before { stub_email_alert_api_does_not_have_subscriber_list(subscriber_list_attributes) }

        it "logs the outcome and does not attempt an update request" do
          update_subscriber_list.trigger

          expect(logger).to have_received(:info).with(
            "subscriber list not found for content id #{document['content_id']}",
          )
        end
      end
    end

    describe "after a major change" do
      let(:update_type) { "major" }

      it_behaves_like "an attempt to update subscriber lists with appropriate logging"
    end

    describe "after a minor change" do
      let(:update_type) { "minor" }

      it_behaves_like "an attempt to update subscriber lists with appropriate logging"
    end
  end
end
