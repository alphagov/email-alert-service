class MessageIdentifier
  def initialize(title, timestamp)
    @title = title
    @timestamp = timestamp
  end

  def create
    create_hexdigest
  end

private

  attr_reader :title, :timestamp

  def create_hexdigest
    Digest::SHA1.hexdigest(title + timestamp)
  end
end
