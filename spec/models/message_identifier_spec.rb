require 'spec_helper'

RSpec.describe MessageIdentifier, "#create" do
  it "generates a hexdigest from a title and timestamp" do
    expected_hexdigest = Digest::SHA1.hexdigest("a title" + Time.now.iso8601)

    generated_hexdigest = MessageIdentifier.new("a title", Time.now.iso8601).create

    expect(expected_hexdigest).to eq generated_hexdigest
  end
end
