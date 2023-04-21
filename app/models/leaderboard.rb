class Leaderboard
  def self.top(n: 3)
    # Quick hack, would be more efficient in SQL but how many players could we
    # possibly have anyway??
    Player.all
      .sort_by(&:high_score)
      .reverse
      .take(n)
      .map {|x| [x.tag, x.high_score] }
  end

  def self.player_highs
    Player.all
      .sort_by(&:tag)
      .map {|x| [x.tag, x.high_score] }
  end
end
