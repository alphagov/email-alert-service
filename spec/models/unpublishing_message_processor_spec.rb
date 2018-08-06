require "spec_helper"

RSpec.describe UnpublishingMessageProcessor do
  let(:delivery_tag) { double(:delivery_tag) }
  let(:delivery_info) { double(:delivery_info, delivery_tag: delivery_tag) }
  let(:properties) { double(:properties, content_type: nil) }

  let(:channel) { double(:channel, acknowledge: nil, reject: nil, nack: nil) }
  let(:logger) { double(:logger, info: nil) }

  let(:processor) { UnpublishingMessageProcessor.new(channel, logger) }
  let(:client) { double(:client) }

  before :each do
    allow(Services).to receive(:email_api_client).and_return(client)
  end
  describe "#process" do
    it 'sends an unpublish message to the email api client' do
      document = { 'content_id' => SecureRandom.uuid }
      expect(client).to receive(:send_unpublish_message).with(document)
      processor.process(document.to_json, properties, delivery_info)
    end
  end

end
