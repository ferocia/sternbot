class Syncer
  def self.sync!
    LOGGER.info("Starting sync as #{SternInsiderScraper.username}")
    scraper = SternInsiderScraper.new
    scraper.login!

    LOGGER.info("Login successful")
    n = 3
    current_leaderboard = AsciiLeaderboard.top(n: n)
    Player.all.each do |player|
      who = player.username
      LOGGER.info("Scraping stats for #{who}")
      stats = scraper.stats_for_player(player.tag)
      score = stats.fetch(:high_score)

      LOGGER.info("Scraped high score for #{who}: #{score}")
      if score > player.high_score.to_i
        LOGGER.info("Storing new high score for #{who}")
        player.high_scores.create!(
          value: score,
          observed_at: Time.zone.now
        )
        SlackNotifier.send_message(":partydino: #{player.tag} has a new personal best of #{score.to_fs(:delimited)}")
      end
    end
    new_leaderboard = AsciiLeaderboard.top(n: n)

    if new_leaderboard != current_leaderboard
      SlackNotifier.send_message("Leaderboard has changed!\n\n```\n#{new_leaderboard}\n```")
    end
  ensure
    scraper.quit
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
