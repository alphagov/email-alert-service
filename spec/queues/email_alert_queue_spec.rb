require "spec_helper"

RSpec.describe EmailAlertQueue do
  describe "#bind" do
    it "binds the queue to an exchange" do
      queue = double(:queue)
      channel = double(:channel, queue: queue)
      exchange = double(:exchange)
      amqp_connection = double(
        :amqp_connection,
        channel: channel,
        exchange: exchange
      )

      expect(queue).to receive(:bind).with(exchange, routing_key: "*.major.#")

      EmailAlertQueue.new(connection: amqp_connection, routing_key: "*.major.#", name: 'name').bind
    end
  end
end
