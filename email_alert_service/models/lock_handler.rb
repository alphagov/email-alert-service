require 'securerandom'

class LockHandler
  class AlreadyLocked < StandardError; end

  SECONDS_IN_A_DAY = 86400

  # We remember sent messages for a long, but limited, period.  The period is
  # limited because we're using redis to store these, which is an in-memory
  # datastore so we can't let it grow indefinitely.
  SECONDS_TO_REMEMBER_SENT_MESSAGES_FOR = (90 * SECONDS_IN_A_DAY).freeze

  # The lock is held while a message is being processed, to ensure that no
  # other worker tries to process the same message concurrently.  It will
  # normally be removed by an explicit call; this timeout is just to ensure
  # that an unclean shutdown of a worker doesn't result in total failure to
  # deliver the message.
  LOCK_PERIOD_IN_SECONDS = 120

  def initialize(email_title, public_updated_at, now = Time.now)
    @email_title = email_title
    @public_updated_at = public_updated_at
    @now = now
  end

  def with_lock_unless_done
    lock!
    begin
      if unhandled_message?
        yield
        mark_message_handled
      end
    ensure
      unlock
    end
  end

private

  attr_reader :email_title, :public_updated_at, :now

  def lock!
    unless try_acquire_lock
      raise AlreadyLocked
    end
  end

  def try_acquire_lock
    temp_key = "temp:#{SecureRandom::base64(18)}"
    redis.multi {
      redis.setex temp_key, LOCK_PERIOD_IN_SECONDS, email_title
      redis.renamenx temp_key, lock_key
      redis.del temp_key
    }[1]
  end

  def unlock
    redis.del lock_key
  end

  def unhandled_message?
    if within_marker_period?
      redis.get(done_marker_key).nil?
    else
      # If we get a message that is too old to have a marker stored, we don't
      # want to send email for that message.
      false
    end
  end

  def mark_message_handled
    redis.setex done_marker_key, SECONDS_TO_REMEMBER_SENT_MESSAGES_FOR, email_title
  end

  def lock_key
    "lock:#{message_key}"
  end

  def done_marker_key
    "done:#{message_key}"
  end

  def message_key
    @_message_key ||= MessageIdentifier.new(email_title, public_updated_at).create
  end

  def within_marker_period?
    seconds_since_public_updated_at < SECONDS_TO_REMEMBER_SENT_MESSAGES_FOR
  end

  def seconds_since_public_updated_at
    now - Time.parse(public_updated_at)
  end

  def redis
    EmailAlertService.services(:redis)
  end
end
