require "json"
require "validators/document_validator"

class Message
  def initialize(document_json, delivery_info)
    @delivery_info = delivery_info
    @document_json = document_json
  end

  def validate_document
    valid_document = validate(parsed_document)
    if valid_document
      valid_document
    else
      raise MalformedDocumentError.new(parsed_document)
    end
  rescue JSON::ParserError
    raise MalformedDocumentError.new(@document_json)
  end

  def delivery_tag
    @delivery_info.delivery_tag
  end

private

  def validate(document)
    if DocumentValidator.new(document).valid?
      document
    end
  end

  def parsed_document
    JSON.parse(@document_json)
  end
end

class MalformedDocumentError < Exception; end
