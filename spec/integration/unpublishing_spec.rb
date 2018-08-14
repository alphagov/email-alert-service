require "spec_helper"

RSpec.describe "Receiving unpublishing notifications", type: :integration do
  include LockHandlerTestHelpers

  let(:document) {
    {
      "base_path" => "path/to-doc",
    }
  }
  let(:client) { double('client', send_unpublish_message: nil) }

  it "sends an unpublishing message" do
    allow(Services).to receive(:email_api_client).and_return(client)
    expect(client).to receive(:send_unpublish_message).with(document)

    with_listener do
      send_message(document.to_json, routing_key: 'redirect.unpublishing')

      wait_for_messages_to_process
    end
  end
end
