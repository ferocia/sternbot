class SlackCommandProcessor
  def self.process(text)
    tokens = text.split(/ +/)
    first = tokens.shift

    if first == ":pinball:"
      case tokens[0]
      when 'hello'
        return "hello"
      when 'help'
        return(<<-EOS)
```
:pinball: leaderboard {3}
:pinball: players
:pinball: add_player {stern_insider_username}
:pinball: remove_player {stern_insider_username}
```
EOS
      when 'leaderboard'
        n = (tokens[1] || 3).to_i
        leaderboard = AsciiLeaderboard.top(n: n)
        return "```\n#{leaderboard}\n```"
      when 'players'
        leaderboard = AsciiLeaderboard.player_highs
        return "```\n#{leaderboard}\n```"
      when 'achievements'
        text = AsciiLeaderboard.achievements
        return "```\n#{text}\n```"
      when 'add'
        username = tokens[1]
        if username
          AddPlayerJob.perform_later(username)
          return "Adding #{username}, stand by..."
        end
      when 'remove'
        username = tokens[1]
        if username
          RemovePlayerJob.perform_later(username)
          return "Removing #{username}, stand by..."
        end
      end
    end
  end
end
