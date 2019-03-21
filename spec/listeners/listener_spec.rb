require "spec_helper"

RSpec.describe Listener do
  let(:queue_binding) { double(:queue_binding) }
  let(:handler) { double(:handler) }

  subject(:listener) { described_class.new(queue_binding, handler) }

  describe "#listen" do
    it "subscribes to the queue binding with manual acknowledgements,
        blocking the thread" do
      expect(queue_binding).to receive(:subscribe).with(
        block: false,
        manual_ack: true,
      )

      listener.listen
    end

    context "when an error occurs processing a message" do
      before do
        delivery_info = double(delivery_tag: nil)
        allow(queue_binding).to receive(:subscribe) { |&block| block.call delivery_info, {}, {} }
        expect(handler).to receive(:process).and_raise("a problem has occured")
      end

      it "exits cleanly and reports the error" do
        expect(GovukError).to receive(:notify)
        expect { listener.listen }.to raise_error(SystemExit)
      end
    end
  end
end
