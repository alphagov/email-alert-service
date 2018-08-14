require "spec_helper"

RSpec.describe Listener do
  describe "#listen" do
    it "subscribes to the queue binding with manual acknowledgements,
        blocking the thread" do
      queue_binding = double(:queue_binding)
      handler = double(:handler)

      expect(queue_binding).to receive(:subscribe).with(
        block: false,
        manual_ack: true,
      )

      Listener.new(queue_binding, handler).listen
    end
  end
end
