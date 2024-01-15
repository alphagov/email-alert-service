class ChangeHistory
  attr_reader :history

  def initialize(history:)
    @history = history
  end

  def latest_change_note
    change_note = history&.max_by { |note| note["public_timestamp"] }
    change_note["note"] if change_note
  end
end
