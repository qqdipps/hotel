class InvalidDateRangeError < StandardError
  def initialize(msg = "Start date must be in the present and before end date.")
    super
  end
end

class RoomNotAvailable < StandardError
  def initialize(msg = "Room not available")
    super
  end
end

class InvalidBlock < StandardError
  def initialize(msg = "Invalid Block. Block aborted.")
    super
  end
end
