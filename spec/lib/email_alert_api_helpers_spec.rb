require "spec_helper"

RSpec.describe EmailAlertApiHelpers do
  describe "#get_subscriber_list" do
    let(:content_id) { SecureRandom.uuid }
    let(:document) { { "content_id" => content_id } }
    let(:subscriber_list_slug) { "slug" }

    let(:subscriber_list_attributes) do
      {
        "id" => "447135c3-07d6-4c3a-8a3b-efa49ef70e52",
        "active_subscriptions_count" => 42,
        "content_id" => content_id,
        "slug" => subscriber_list_slug,
        "title" => "title",
      }
    end

    let(:logger) { double(:logger, info: nil) }
    let(:helper) { MockClass.new(document, logger) }

    context "given a document with content ID matching a subscriber list" do
      before { stub_email_alert_api_has_subscriber_list(subscriber_list_attributes) }

      it "creates a subscriber_list instance varaible containing subscriber_list data from email-alert-api" do
        helper.get_subscriber_list
        expect(helper.instance_variable_get("@subscriber_list")).to eq(subscriber_list_attributes)
      end

      it "creates a @subscriber_list_slug instance varaible containing subscriber_list data from email-alert-api" do
        helper.get_subscriber_list
        expect(helper.instance_variable_get("@subscriber_list_slug")).to eq(subscriber_list_slug)
      end
    end

    context "given a document with a content ID that does not match a subscriber list" do
      before { stub_email_alert_api_does_not_have_subscriber_list(subscriber_list_attributes) }

      it "does not set a @subscriber_list instance variable" do
        helper.get_subscriber_list
        expect(helper.instance_variable_defined?("@subscriber_list")).to be false
      end

      it "does not set a @subscriber_list_slug instance variable" do
        helper.get_subscriber_list
        expect(helper.instance_variable_defined?("@subscriber_list_slug")).to be false
      end

      it "logs that the subscriber list was not found" do
        helper.get_subscriber_list
        expect(logger).to have_received(:info).with(
          "subscriber list not found for content id #{document['content_id']}",
        )
      end
    end
  end
end

class MockClass
  include EmailAlertApiHelpers

  attr_reader :document, :logger

  def initialize(document, logger)
    @document = document
    @logger = logger
  end
end
