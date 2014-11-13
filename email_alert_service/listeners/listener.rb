class Listener
  def initialize(queue_binding, processor)
    @processor = processor
    @queue_binding = queue_binding
  end

  def listen
    @queue_binding.subscribe(block: true, manual_ack: true) do |delivery_info, properties, document_json|
      @processor.process(document_json, properties, delivery_info)
    end
  end
end
