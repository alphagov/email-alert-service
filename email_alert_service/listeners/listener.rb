class Listener
  def initialize(queue_binding, handler)
    @handler = handler
    @queue_binding = queue_binding
  end

  def listen
    @queue_binding.subscribe(block: true, manual_ack: true) do |delivery_info, _, document_json|
      @handler.handle(delivery_info, document_json)
    end
  end
end
