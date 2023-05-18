class Syncer
  def self.slack_notifier
    @slack_notifier ||= SlackNotifier
  end

  def self.sync!(notify: false, username: nil)
    LOGGER.info("Starting sync as #{SternInsiderScraper.username}")
    scraper = SternInsiderScraper.new
    scraper.login!

    LOGGER.info("Login successful")
    n = 3
    current_leaderboard = AsciiLeaderboard.top(n: n)
    players = if username.present?
      Player.where(username:)
    else
      Player.all
    end

    players.each do |player|
      player_notify = notify && player.synced_at
      who = player.username
      LOGGER.info("Scraping stats for #{who}")
      stats = scraper.stats_for_player(player)
      now = Time.zone.now
      score = stats.fetch(:high_score)
      plays = stats.fetch(:plays)
      as = stats.fetch(:achievements)
      stern_id = stats.fetch(:stern_id, nil)
      notifications = []

      Player.transaction do
        LOGGER.info("Scraped high score for #{who}: #{score}")

        # this is pretty much temporary until every player has a stern id
        if player.stern_id.nil? && stern_id.present?
          LOGGER.info("Updating the stern id for #{who} to #{stern_id}")
          player.update(stern_id:)
        end

        if score > player.high_score.to_i
          LOGGER.info("Storing new high score for #{who}")
          player.high_scores.create!(
            value: score,
            observed_at: now
          )
          notifications << ":partydino: #{player.tag} has a new personal best of #{score.to_fs(:delimited)}"
        end
        LOGGER.info("Updating plays for #{who}: #{plays}")
        player.update(plays: plays)

        already = player.achievements.map(&:slug)
        diff = as - already
        if diff.any?
          LOGGER.info("New achievements for #{who}: #{diff}")
          diff.each do |slug|
            a = Achievements.find(slug)
            player.achievements.create!(
              slug: slug,
              observed_at: now
            )
            notifications << ":partydino: #{player.tag} achieved #{a.name} (#{a.description})"
          end
        end
        player.update(synced_at: now)
      end

      notifications.each do |notification|
        notify(notification, player_notify)
      end
    end
    new_leaderboard = AsciiLeaderboard.top(n: n)

    if new_leaderboard != current_leaderboard
      notify("Leaderboard has changed!\n\n```\n#{new_leaderboard}\n```", notify)
    end
  ensure
    scraper.quit
  end

  def self.notify(message, slack_it)
    slack_notifier.send_message(message) if slack_it
    LOGGER.info("Sending to Slack: #{message}")
  end

  def self.add_player!(username)
    player = Player.find_by(username: username)
    return player if player

    scraper = SternInsiderScraper.new
    scraper.login!
    res = scraper.add_connection!(username)
    if res[:tag]
      player = Player.create!(tag: res[:tag], username: username, stern_id: res[:stern_id])
      scraper.quit
      player
    end
  end

  def self.remove_player!(username)
    p = Player.find_by(username: username)
    return unless p

    scraper = SternInsiderScraper.new
    scraper.login!
    if scraper.remove_connection!(username)
      p.destroy
    end

    scraper.quit
  end
end
