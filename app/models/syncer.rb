class Syncer
  def self.sync!(notify: false, username: nil)
    LOGGER.info("Starting sync as #{SternInsiderScraper.username}")
    scraper = SternInsiderScraper.new
    scraper.login!

    LOGGER.info("Login successful")
    n = 3
    current_leaderboard = AsciiLeaderboard.top(n: n)
    Player.all.each do |player|
      next if username && player.username != username
      player_notify = notify && !player.synced_at
      who = player.username
      LOGGER.info("Scraping stats for #{who}")
      stats = scraper.stats_for_player(player.tag)
      now = Time.zone.now
      score = stats.fetch(:high_score)
      plays = stats.fetch(:plays)
      as = stats.fetch(:achievements)
      notifications = []

      Player.transaction do
        LOGGER.info("Scraped high score for #{who}: #{score}")
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
    SlackNotifier.send_message(message) if slack_it
    LOGGER.info("Sending to Slack: #{message}")
  end

  def self.add_player!(username)
    player = Player.find_by(username: username)
    return player if player

    scraper = SternInsiderScraper.new
    scraper.login!
    tag = scraper.add_connection!(username)
    if tag
      player = Player.create!(tag: tag, username: username)
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
