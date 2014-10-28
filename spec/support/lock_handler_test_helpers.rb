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
    Time.at(ninety_days_before(updated_now)).strftime("%l:%M%P, %-d %B %Y")
  end

  def updated_now
    Time.now.strftime("%l:%M%P, %-d %B %Y")
  end

  def expired_formatted_email
    { "title" => "Example Alert", "public_updated_at" => expired_date }
  end

  def formatted_email
    { "title" => "Example Alert", "public_updated_at" => updated_now }
  end

  def lock_key_for_formatted_email
    Digest::SHA1.hexdigest formatted_email["title"] + formatted_email["public_updated_at"]
  end
end
