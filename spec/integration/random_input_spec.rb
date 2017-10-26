require "spec_helper"

RSpec.describe "Random input", type: :integration do
  let(:delivery_info) { double(:delivery_info, delivery_tag: double(:delivery_tag)) }
  let(:properties) { double(:properties, content_type: nil) }
  let(:channel) { double(:channel, acknowledge: nil, reject: nil) }
  let(:logger) { double(:logger, info: nil) }

  schemas = GovukSchemas::Schema.all(schema_type: "notification")
  schemas.each do |name, schema|
    it "can handle #{name}" do
      stub_request(:post, "https://email-alert-api.test.gov.uk/notifications").
        to_return(body: "{}")

      processor = MessageProcessor.new(channel, logger)

      5.times do
        random_example = GovukSchemas::RandomExample.new(schema: schema).payload
        processor.process(JSON.dump(random_example), properties, delivery_info)
      end
    end
  end
end
