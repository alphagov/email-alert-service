require "spec_helper"

RSpec.describe LockHandler do
  let(:lock_handler) { LockHandler.new(formatted_email) }

  before :each do
    allow(Redis).to receive(:new).and_return(mock_redis)
  end

  describe "#validate_and_set_lock" do
    context "if formatted email is within valid period" do
      it "checks that the formatted email is within the valid expiry period" do
        expect(lock_handler).to receive(:within_valid_lock_period?).and_call_original
        expect(lock_handler).to receive(:set_lock)

        lock_handler.validate_and_set_lock
      end

      it "sets a lock key for the formatted email if no current key exists" do
        expect(mock_redis).to receive(:setnx).once

        lock_handler.validate_and_set_lock
      end

      it "does not set a lock key for the formatted email if a current key exists" do
        expect(lock_handler.validate_and_set_lock).to eq true
        expect(lock_handler.validate_and_set_lock).to eq false
      end
    end

    context "if formatted email has expired" do
      it "checks that the  formatted email is within the valid expiry period" do
        lock_handler = LockHandler.new(expired_formatted_email)

        expect(lock_handler).to receive(:within_valid_lock_period?).and_call_original
        expect(lock_handler).to_not receive(:set_lock)

        lock_handler.validate_and_set_lock
      end
    end
  end

  describe "#set_lock_expiry" do
    it "sets an expiry period for formatted email" do
      lock_expiry_period = Time.parse(formatted_email["public_updated_at"]).to_i + (90 * 86400)

      expect(mock_redis).to receive(:expireat).with(lock_key_for_formatted_email, lock_expiry_period)

      lock_handler.set_lock_expiry
    end
  end
end
