require "spec_helper"
require "queues/major_change_queue"

RSpec.describe MajorChangeQueue do
  describe "#bind" do
    it "binds the queue to an exchange" do
      queue = double(:queue)
      channel = double(:channel, queue: queue)
      amqp_connection = double(
        :amqp_connection,
        channel: channel,
        exchange: "test exchange",
        queue_name: "queue name"
      )

      expect(queue).to receive(:bind).with(amqp_connection.exchange, routing_key: "*.major.#")

      MajorChangeQueue.new(amqp_connection).bind
    end
  end
end
