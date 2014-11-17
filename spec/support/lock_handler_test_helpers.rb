require "mock_redis"

module LockHandlerTestHelpers
  def mock_redis
    @_mock_redis ||= MockRedis.new
  end

  def seconds_in_three_months
    90 * 86400
  end

  def ninety_days_before(date_string)
    (Time.parse(date_string).to_i - seconds_in_three_months)
  end

  def expired_date
    Time.at(ninety_days_before(updated_now)).iso8601
  end

  def updated_now
    Time.now.iso8601
  end

  def generate_title
    sample = Array(1..100).sample

    "Example title #{sample}"
  end

  def expired_email_data
    { "formatted" => { "subject" => "Example Alert" }, "public_updated_at" => expired_date }
  end

  def email_data
    { "formatted" => { "subject" => "Example Alert" }, "public_updated_at" => updated_now }
  end

  def lock_key_for_email_data
    Digest::SHA1.hexdigest email_data["formatted"]["subject"] + email_data["public_updated_at"]
  end
end
