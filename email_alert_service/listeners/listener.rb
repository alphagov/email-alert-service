class Listener
  def initialize(queue_binding, processor)
    @processor = processor
    @queue_binding = queue_binding
  end

  def listen
    @queue_binding.subscribe(block: true, manual_ack: true) do |delivery_info, _, document_json|
      @processor.process(document_json, delivery_info)
    end
  end
end
