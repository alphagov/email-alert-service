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
        expect(lock_handler).to receive(:set_lock_with_expiry).and_call_original

        lock_handler.validate_and_set_lock
      end

      it "sets a lock key and expiry within a atomic execution for the formatted email if no current key exists" do
        expect(mock_redis).to receive(:multi).once.and_call_original
        expect(mock_redis).to receive(:setnx).once
        expect(mock_redis).to receive(:expireat).once

        lock_handler.validate_and_set_lock
      end

      it "does not set a lock key for the formatted email if a current key exists" do
        expect(lock_handler.validate_and_set_lock).to eq true
        expect(lock_handler.validate_and_set_lock).to eq false
      end

      it "logs a message if the lock is already set" do
        mock_logger = double
        logger_message = "A lock for the message with title: #{formatted_email["title"]} and email_updated_at: #{formatted_email["public_updated_at"]} already exists"

        allow_any_instance_of(LockHandler).to receive(:logger).and_return(mock_logger)
        expect(mock_logger).to receive(:info).with(logger_message)

        2.times do
          lock_handler.validate_and_set_lock
        end
      end
    end

    context "if formatted email has expired" do
      it "checks that the  formatted email is within the valid expiry period" do
        lock_handler = LockHandler.new(expired_formatted_email)

        expect(lock_handler).to receive(:within_valid_lock_period?).and_call_original
        expect(lock_handler).to_not receive(:set_lock_with_expiry)

        lock_handler.validate_and_set_lock
      end
    end
  end
end
