require "spec_helper"
require "connections/amqp_connection"

RSpec.describe AMQPConnection do
  let(:config_options) { {exchange: "example exchange", queue: "example queue"} }

  describe "#start" do
    it "starts a connection to the rabbitmq server" do
      rabbitmq_service = double(:rabbitmq_service)
      allow(Bunny).to receive(:new).with(config_options).and_return(rabbitmq_service)

      expect(rabbitmq_service).to receive(:start)

      AMQPConnection.new(config_options).start
    end
  end

  describe "#stop" do
    it "closes the connection channel and the stops the connection to the rabbitmq server" do
      channel = double(:channel, prefetch: nil)
      rabbitmq_service = double(:rabbitmq_service, create_channel: channel)
      allow(Bunny).to receive(:new).with(config_options).and_return(rabbitmq_service)

      expect(channel).to receive(:close)
      expect(rabbitmq_service).to receive(:stop)

      AMQPConnection.new(config_options).stop
    end
  end

  describe "#channel" do
    it "creates a channel with prefetch of 1 on the rabbitmq server" do
      rabbitmq_service = double(:rabbitmq_service)
      allow(Bunny).to receive(:new).with(config_options).and_return(rabbitmq_service)

      rabbitmq_channel = double(:rabbitmq_channel)
      expect(rabbitmq_service).to receive(:create_channel).and_return(rabbitmq_channel)
      expect(rabbitmq_channel).to receive(:prefetch).with(1)

      AMQPConnection.new(config_options).channel
    end
  end

  describe "#exchange" do
    it "connects to the exchange on the rabbitmq server" do
      channel = double(:channel, prefetch: nil)
      rabbitmq_service = double(:rabbitmq_service, create_channel: channel)
      allow(Bunny).to receive(:new).with(config_options).and_return(rabbitmq_service)

      expect(channel).to receive(:topic).with(config_options.fetch(:exchange), passive: true)

      AMQPConnection.new(config_options).exchange
    end
  end
end
