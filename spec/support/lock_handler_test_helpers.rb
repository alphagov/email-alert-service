module LockHandlerTestHelpers
  def seconds_in_90_days
    90 * 86400
  end

  def expired_date
    updated_now - seconds_in_90_days
  end

  def updated_now
    @updated_now ||= Time.now
  end

  def generate_title
    sample = Array(1..100).sample

    "Example title #{sample}"
  end

  def expired_email_data
    { "formatted" => { "subject" => "Example Alert" }, "public_updated_at" => expired_date.iso8601 }
  end

  def email_data
    { "formatted" => { "subject" => "Example Alert" }, "public_updated_at" => updated_now.iso8601 }
  end

  def identifier_hash_for(document)
    Digest::SHA1.hexdigest(document["title"] + document["public_updated_at"])
  end

  def message_key_for_email_data
    MessageIdentifier.new(
      email_data["formatted"]["subject"],
      email_data["public_updated_at"],
    ).create
  end

  def lock_key_for_email_data
    "lock:#{message_key_for_email_data}"
  end

  def done_marker_for_email_data
    "done:#{message_key_for_email_data}"
  end
end
