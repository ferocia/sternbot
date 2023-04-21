class AsciiLeaderboard
  def self.top(n: 3)
    t = Terminal::Table.new(headings: %w(# Tag Score))
    Leaderboard.top(n: n).each do |x|
      t << [
        x[0],
        x[1],
        x[2] ? x[2].to_fs(:delimited) : ""
      ]
    end
    t.to_s
  end

  def self.player_highs
    t = Terminal::Table.new(headings: %w(Tag Score))
    Leaderboard.player_highs.each do |x|
      t << [
        x[0],
        x[1] ? x[1].to_fs(:delimited) : ""
      ]
    end
    t.to_s
  end
end
