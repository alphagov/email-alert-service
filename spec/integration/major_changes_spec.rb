require "spec_helper"

require "config"
require "bunny"

RSpec.describe "Receiving major change notifications", type: :integration do
  let(:well_formed_document) { '{"title": "This is a sample document"}' }
  let(:malformed_json) { '{23o*&£}' }
  let(:malformed_document) { '{"houses": "are for living in"}' }

  before do
    @logfile, @thread, @listener = start_listener
  end

  after do
    @listener.stop

    @thread.kill

    while @thread.alive?
      sleep 0.1
    end
  end

  it "prints the title of documents experiencing major changes" do
    send_message(well_formed_document, routing_key: "policy.major")
    send_message(well_formed_document, routing_key: "news_article.major")

    wait_for_messages_to_process

    @logfile.rewind
    output = @logfile.read
    document_occurrences = output.scan(/This is a sample document/)

    expect(document_occurrences.count).to eq(2)
  end

  it "doesn't receive documents with other change types" do
    send_message(well_formed_document, routing_key: "policy.minor")
    send_message(well_formed_document, routing_key: "policy.republish")

    wait_for_messages_to_process

    @logfile.rewind
    expect(@logfile.read).not_to match(/This is a sample document/)
  end

  it "does not print anything for a malformed document" do
    send_message(malformed_document)
    send_message(malformed_json)

    wait_for_messages_to_process

    @logfile.rewind
    expect(@logfile.read).not_to match(/Received major change/)
  end
end
