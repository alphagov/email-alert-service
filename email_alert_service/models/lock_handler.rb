class LockHandler

  SECONDS_IN_A_DAY = 86400.freeze
  VALID_LOCK_PERIOD_IN_SECONDS = (90 * SECONDS_IN_A_DAY).freeze

  def initialize(formatted_email)
    @formatted_email = formatted_email
    @formatted_email_title = formatted_email.fetch("title")
    @formatted_email_updated_at = formatted_email.fetch("public_updated_at")
  end

  def validate_and_set_lock
    if within_valid_lock_period?
      set_lock
    end
  end

  def set_lock_expiry
    redis.expireat lock_key_id, lock_expiry_period
  end

private

  attr_reader :formatted_email, :formatted_email_title, :formatted_email_updated_at

  def set_lock
    redis.setnx lock_key_id, formatted_email_title
  end

  def lock_key_id
    @_lock_key_id ||= Digest::SHA1.hexdigest formatted_email_title + formatted_email_updated_at
  end

  def within_valid_lock_period?
    seconds_since_formatted_email_updated_at < VALID_LOCK_PERIOD_IN_SECONDS
  end

  def lock_expiry_period
    formatted_email_updated_at_in_seconds + VALID_LOCK_PERIOD_IN_SECONDS
  end

  def formatted_email_updated_at_in_seconds
    Time.parse(formatted_email_updated_at).to_i
  end

  def seconds_since_formatted_email_updated_at
    Time.now.to_i - formatted_email_updated_at_in_seconds
  end

  def redis
    @_redis ||= Redis.new
  end
end
