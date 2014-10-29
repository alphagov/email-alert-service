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
      key_and_expiry_status = set_lock_with_expiry
      log_key_status(key_and_expiry_status[0])
      key_and_expiry_status[0]
    end
  end

private

  attr_reader :formatted_email, :formatted_email_title, :formatted_email_updated_at

  def log_key_status(key_status)
    unless key_status
      logger.info "A lock for the message with title: #{formatted_email_title} and email_updated_at: #{formatted_email_updated_at} already exists"
    end
  end

  def set_lock_with_expiry
    redis.multi do
      redis.setnx lock_key_id, formatted_email_title
      redis.expireat lock_key_id, lock_expiry_period
    end
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

  def logger
    EmailAlertService.config.logger
  end
end
