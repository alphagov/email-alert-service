require "spec_helper"

RSpec.describe UnpublishingMessageProcessor do
  let(:payload) { { content_id: SecureRandom.uuid } }
  let(:message) { double(:message, ack: nil, discard: nil, retry: nil, payload: payload) }
  let(:logger)  { double(:logger, info: nil) }

  let(:processor) { UnpublishingMessageProcessor.new(logger) }
  let(:client)    { double(:client) }

  before :each do
    allow(Services).to receive(:email_api_client).and_return(client)
  end

  describe "#process" do
    it "sends an unpublish message to the email api client" do
      expect(client).to receive(:send_unpublish_message).with(payload)
      processor.process(message)
    end
  end
end
