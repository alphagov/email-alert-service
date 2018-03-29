class ChangeHistory
  attr_reader :history

  def initialize(history:)
    @history = history
  end

  def latest_change_note
    change_note = history&.sort_by { |note| note["public_timestamp"] }&.last
    change_note["note"] if change_note
  end
end
