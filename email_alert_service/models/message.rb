require "json"
require "validators/document_validator"

class Message
  def initialize(document_json, properties, delivery_info)
    @delivery_info = delivery_info
    @properties = properties
    @document_json = document_json
  end

  def parsed_document
    @_parsed_document ||= JSON.parse(@document_json)
  rescue JSON::ParserError
    raise MalformedDocumentError.new(@document_json)
  end

  def validate!
    if DocumentValidator.new(parsed_document).valid?
      parsed_document
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
end

class MalformedDocumentError < StandardError; end
class InvalidDocumentError < StandardError; end
