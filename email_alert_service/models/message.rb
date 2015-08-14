require "json"
require "validators/document_validator"

class Message
  def initialize(document_json, properties, delivery_info)
    @delivery_info = delivery_info
    @properties = properties
    @document_json = document_json
  end

  def validate_document
    valid_document = validate(parsed_document)
    if valid_document
      valid_document
    else
      raise InvalidDocumentError.new(parsed_document)
    end
  end

  def delivery_tag
    @delivery_info.delivery_tag
  end

  def heartbeat?
    @properties.content_type == "application/x-heartbeat"
  end

private

  def validate(document)
    if DocumentValidator.new(document).valid?
      document
    end
  end

  def parsed_document
    JSON.parse(@document_json)
  rescue JSON::ParserError
    raise MalformedDocumentError.new(@document_json)
  end
end

class MalformedDocumentError < StandardError; end
class InvalidDocumentError < StandardError; end
