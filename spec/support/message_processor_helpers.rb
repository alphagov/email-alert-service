module MessageProcessorHelpers
  def message_acknowledged
    expect(message).to have_received(:ack)
  end

  def message_rejected
    expect(message).to have_received(:discard)
  end

  def message_requeued
    expect(message).to have_received(:retry)
  end
end
