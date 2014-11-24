require "spec_helper"

RSpec.describe LockHandler do
  include LockHandlerTestHelpers

  let(:lock_handler) {
    LockHandler.new(
      email_data["formatted"]["subject"],
      email_data["public_updated_at"],
      updated_now,
    )
  }

  let(:redis) { EmailAlertService.services(:redis) }
  let(:redis_connection) { redis.redis }

  after :each do
    redis.flushdb
  end

  describe "#run" do
    context "if email is within valid period" do
      it "obtains and releases lock" do
        expect(lock_handler).to receive(:lock!).and_call_original
        expect(lock_handler).to receive(:unlock).and_call_original

        lock_handler.run {}
      end

      it "raises an exception and remains locked if already locked" do
        lock_handler.send(:lock!)

        expect { lock_handler.run {} }.to raise_error(LockHandler::AlreadyLocked)
        expect { lock_handler.run {} }.to raise_error(LockHandler::AlreadyLocked)
      end

      it "unlock removes the lock" do
        lock_handler.send(:lock!)
        expect { lock_handler.run {} }.to raise_error(LockHandler::AlreadyLocked)

        lock_handler.send(:unlock)
        lock_handler.run {}
      end

      it "the lock has a TTL of two minutes" do
        lock_handler.send(:lock!)

        ttl = redis.ttl(lock_key_for_email_data)
        expect(ttl).to be <= 120
        expect(ttl).to be > 0
      end

      it "only calls the block for a given message the first time" do
        expect { |b| lock_handler.run(&b) }.to yield_with_no_args
        expect { |b| lock_handler.run(&b) }.not_to yield_control
      end

      it "will call the block again if it raised an exception" do
        expect {
          lock_handler.run { raise RuntimeError }
        }.to raise_error(RuntimeError)

        expect { |b| lock_handler.run(&b) }.to yield_control
      end

      it "sets only the done marker in redis" do
        lock_handler.run {}

        expect(redis.keys).to eq([done_marker_for_email_data])
      end

      it "the done marker has a TTL of 90 days" do
        lock_handler.run {}

        ttl = redis.ttl(done_marker_for_email_data)
        expect(ttl).to be <= 86400 * 90
        expect(ttl).to be > 86400 * 89
      end
    end

    context "if email is too old to handle" do
      let(:lock_handler) {
        LockHandler.new(
          expired_email_data["formatted"]["subject"],
          expired_email_data["public_updated_at"],
          updated_now,
        )
      }

      it "won't call the block" do
        expect { |b| lock_handler.run(&b) }.not_to yield_control
      end

      it "won't set the done marker" do
        lock_handler.run {}

        expect(redis.keys).to eq([])
      end
    end

    it "uses configured redis namespace for lock keys" do
      lock_handler.send(:lock!)
      namespaced_lookup = redis_connection.get("email-alert-service:#{lock_key_for_email_data}")
      non_namespaced_lookup = redis_connection.get(lock_key_for_email_data)

      expect(namespaced_lookup).to eq email_data["formatted"]["subject"]
      expect(non_namespaced_lookup).to be_nil
    end
  end
end
