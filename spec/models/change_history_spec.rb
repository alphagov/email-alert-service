require "spec_helper"

RSpec.describe ChangeHistory do
  describe "#latest_change_note" do
    context "change_history is nil" do
      let(:change_history) { ChangeHistory.new(history: nil) }
      it "returns nil" do
        expect(change_history.latest_change_note).to be_nil
      end
    end

    context "change_history has one entry" do
      let(:change_history) do
        ChangeHistory.new(
          history: [
            {
              "public_timestamp": "2017-10-19T16:09:23.000+01:00",
              "note" => "latest change note",
            },
          ],
        )
      end

      it "returns the note" do
        expect(change_history.latest_change_note).to eq("latest change note")
      end
    end

    context "change_history has multiple entries" do
      let(:change_history) do
        ChangeHistory.new(
          history: [
            {
              "public_timestamp": "2017-10-18T16:09:23.000+01:00",
              "note" => "a different change note",
            },
            {
              "public_timestamp": "2017-10-19T16:09:23.000+01:00",
              "note" => "latest change note",
            },
          ],
        )
      end

      it "returns the latest" do
        expect(change_history.latest_change_note).to eq("latest change note")
      end
    end
  end
end
