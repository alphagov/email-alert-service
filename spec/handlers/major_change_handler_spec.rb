require "spec_helper"
require "handlers/major_change_handler"

RSpec.describe MajorChangeHandler do
  let(:delivery_tag) { double(:delivery_tag) }
  let(:delivery_info) { double(:delivery_info, delivery_tag: delivery_tag) }
  let(:channel) {
    double(:channel,
      acknowledge: nil,
      reject: nil
    )
  }
  let(:handler) { MajorChangeHandler.new(channel) }

  describe "#handle(delivery_info, document_json)" do
    it "acknowledges the message if all goes well" do
      handler.handle(delivery_info, '{"title": "Example policy"}')

      expect(channel).to have_received(:acknowledge).with(
        delivery_tag,
        false
      )
    end

    it "discards the message if there's a JSON parser error" do
      handler.handle(delivery_info, '{]$£$*()}')

      expect(channel).to have_received(:reject).with(
        delivery_tag,
        false
      )
    end
  end
end
