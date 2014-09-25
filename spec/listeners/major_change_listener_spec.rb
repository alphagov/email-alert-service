require "spec_helper"
require "listeners/major_change_listener"

RSpec.describe MajorChangeListener do
  let(:connection) {
    double(:connection,
      create_channel: channel,
      start: nil,
      close: nil
    )
  }
  let(:channel) {
    double(:channel,
      topic: exchange,
      queue: queue,
      close: nil
    )
  }
  let(:exchange) { double(:exchange) }
  let(:queue) {
    double(:queue,
      bind: nil,
      subscribe: nil
    )
  }

  before do
    allow(Bunny).to receive(:new).and_return(connection)
  end

  describe "#run" do
    it "starts the connection" do
      build_listener.run

      expect(connection).to have_received(:start)
    end

    it "opens a passive topic exchange with the configured name" do
      build_listener("exchange" => "a_test_exchange").run

      expect(channel).to have_received(:topic).with(
        "a_test_exchange",
        passive: true
      )
    end

    it "creates a non-exclusive queue with the configured name" do
      build_listener("queue" => "a_test_queue").run

      expect(channel).to have_received(:queue).with("a_test_queue")
    end

    it "binds the queue to the exchange with the major change routing pattern" do
      build_listener.run

      expect(queue).to have_received(:bind).with(
        exchange,
        routing_key: "*.major.#"
      )
    end

    it "subscribes to the queue with manual acknowledgements,
        blocking the thread" do
      build_listener.run

      expect(queue).to have_received(:subscribe).with(
        manual_ack: true,
        block: true
      )
    end
  end

  describe "#stop" do
    it "closes the channel and connection" do
      listener = build_listener
      listener.run
      listener.stop

      expect(channel).to have_received(:close)
      expect(connection).to have_received(:close)
    end

    it "doesn't complain if the listener hasn't been started" do
      build_listener.stop

      expect(channel).not_to have_received(:close)
      expect(connection).to have_received(:close)
    end
  end

  def build_listener(options = {})
    options = {
      "exchange" => "example_exchange",
      "queue" => "example_queue"
    }.merge(options)

    MajorChangeListener.new(options)
  end
end
