class AsciiLeaderboard
  def self.top(n: 3)
    t = new_table!(%w(# Tag Score))
    Leaderboard.top(n: n).each do |x|
      t << [
        x[0],
        x[1],
        x[2] ? x[2].to_fs(:delimited) : ""
      ]
    end
    t.align_column(2, :right)
    t.to_s
  end

  def self.player_highs
    t = new_table!(%w(Tag Username Best))
    Leaderboard.player_highs.each do |x|
      t << [
        x[0],
        x[1],
        x[2] ? x[2].to_fs(:delimited) : ""
      ]
    end
    t.align_column(2, :right)
    t.to_s
  end

  def self.new_table!(headings)
    t = Terminal::Table.new(headings: headings)
    t.style = {
      :border => :unicode,
      :border_top => false,
      :border_bottom => false,
      :border_right => false,
      :border_left => false,
    }
    t
  end
end
