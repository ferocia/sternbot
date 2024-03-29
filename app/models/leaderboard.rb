class Leaderboard
  def self.top(n: 3)
    # Quick hack, would be more efficient in SQL but how many players could we
    # possibly have anyway??
    Player.all
      .sort_by {|x| x.high_score.to_i }
      .reverse
      .take(n)
      .select {|x| x.high_score }
      .map.with_index {|x, i| [i + 1, x.tag, x.high_score] }
  end

  def self.player_highs
    Player.all
      .sort_by(&:tag)
      .map {|x| [x.tag, x.username, x.plays, x.high_score] }
  end

  def self.player_score_history(tag, n: 5)
    Player
      .find_by!(tag: tag.upcase)
      .highest_scores(n: n)
      .map {|x| [x.value, x.observed_at] }
  end

  def self.achievements(tag: nil)
    data = {}
    scope = Achievement.includes(:player)
    as = scope.all
    as.each do |a|
      a_data = Achievements.find(a.slug)
      data[a_data.name] ||= []
      if tag.nil? || tag.upcase == a.player.tag.upcase
        data[a_data.name] << a.player.tag
      end
    end
    denominator = Player.count

    data = data.map {|row|
      row << row[1].length / denominator.to_f
    }

    data =
      if tag
        data.sort_by {|slug, ps| slug }
      else
        data.sort_by {|slug, ps| [-ps.size, slug] }
      end
    data
  end
end
