# frozen_string_literal: true

module TimeConverter
  def self.sec2time(wall_time)
    seconds = wall_time.round
    h, m, s = seconds / 3600, (seconds % 3600) / 60, seconds % 60
    "#{h}:#{m}:#{s}"
  end
end
