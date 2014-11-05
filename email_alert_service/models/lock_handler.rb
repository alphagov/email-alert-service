class LockHandler

  SECONDS_IN_A_DAY = 86400.freeze
  VALID_LOCK_PERIOD_IN_SECONDS = (90 * SECONDS_IN_A_DAY).freeze

  def initialize(email_title, public_updated_at)
    @email_title = email_title
    @public_updated_at = public_updated_at
  end

  def validate_and_set_lock
    if within_valid_lock_period?
      key_and_expiry_status = set_lock_with_expiry
      log_key_status(key_and_expiry_status[0])
      key_and_expiry_status[0]
    end
  end

private

  attr_reader :email_title, :public_updated_at

  def log_key_status(key_status)
    unless key_status
      logger.info "A lock for the message with title: #{email_title} and public_updated_at: #{public_updated_at} already exists"
    end
  end

  def set_lock_with_expiry
    redis.multi do
      redis.setnx lock_key_id, email_title
      redis.expireat lock_key_id, lock_expiry_period
    end
  end

  def lock_key_id
    @_lock_key_id ||= Digest::SHA1.hexdigest email_title + public_updated_at
  end

  def within_valid_lock_period?
    seconds_since_public_updated_at < VALID_LOCK_PERIOD_IN_SECONDS
  end

  def lock_expiry_period
    public_updated_at_in_seconds + VALID_LOCK_PERIOD_IN_SECONDS
  end

  def public_updated_at_in_seconds
    Time.parse(public_updated_at).to_i
  end

  def seconds_since_public_updated_at
    Time.now.to_i - public_updated_at_in_seconds
  end

  def redis
    @_redis ||= Redis.new
  end

  def logger
    EmailAlertService.config.logger
  end
end
