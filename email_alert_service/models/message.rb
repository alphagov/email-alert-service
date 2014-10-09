require "json"
require "validators/document_validator"

class Message
  def initialize(document_json, delivery_info)
    @delivery_info = delivery_info
    @document_json = document_json
  end

  def validate_document
    validate(parsed_document)
  rescue InvalidDocument => e
    raise MalformedDocumentError.new(e.message)
  rescue JSON::ParserError => e
    raise MalformedDocumentError.new(e.message)
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
