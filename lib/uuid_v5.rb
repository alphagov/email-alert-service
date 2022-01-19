require "uuidtools"

module UUIDv5
  def self.call(namespace, name)
    # Creates a UUID using the SHA1 hash.  (Version 5)
    UUIDTools::UUID.sha1_create(
      UUIDTools::UUID.parse(namespace),
      name,
    ).to_s
  end
end
