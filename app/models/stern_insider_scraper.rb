Capybara.threadsafe = true

class SternInsiderScraper
  def self.username
    ENV.fetch("INSIDER_USERNAME")
  end

  def self.stern_id_from_url(url)
    url.match(/connections\/(\d+)\//)[1]
  end

  def self.stats_page_url_for(player)
    "/insider/connections/#{player.stern_id}/stats"
  end

  def self.godzilla_stats_page_url_for(player)
    "/insider/connections/#{player.stern_id}/gameStats/106"
  end

  def login!
    session.visit '/login'

    session.fill_in 'Email', with: self.class.username
    session.fill_in 'Password', with: ENV.fetch("INSIDER_PASSWORD")

    session.click_button 'Done'

    session.click_link 'Connections'

    @default_url = session.current_url

    true
  end

  def stats_for_player(player)
    if player.stern_id.present?
      session.visit godzilla_stats_page_url_for(player)
    else
      session.find('a', text: player_tag).click
      session.click_link 'Godzilla'
    end

    summary_tds = session.find('th', text: 'HIGH SCORE')
      .ancestor('table')
      .find('tbody')
      .find('tr')        # Only one row in this table
      .find_all('td')

    score = summary_tds[1].text
    plays = summary_tds[2].text

    achievements = []
    section = session.find('h1', text: 'Achievements')
      .find(:xpath, 'ancestor-or-self::section[1]')

    groups = section.find_all('li.px-6')

    groups.each do |group|
      name = group.find('.text-xs').text
      stars = group.find_all('li').map(&:text).map {|x| x.match?(/^Complete/) }
      slugs = Achievements.slugs_for(name)

      if stars.length != slugs.length
        raise "unexpected lengths, #{stars.inspect} vs #{slugs.inspect}"
      end

      achievements += slugs.zip(stars).select {|_, x| x }.map(&:first)
    end

    stern_id = self.stern_id_from_url(session.current_url)

    return_to_connections_page

    {
      high_score: score.gsub(/[^0-9]/, "").to_i,
      plays: plays.gsub(/[^0-9]/, "").to_i,
      achievements: achievements,
      stern_id:,
    }
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    end
    raise e
  end

  def add_connection!(username)
    search_for(username)

    # we want to match the username exactly, but allow for variations in case
    user_row = session.find('span', exact_text: /#{username}/i).ancestor('li')

    if user_row.has_button?("Follow")
      user_row.click_button "Follow"
    end

    tag = user_row.find('p.uppercase').text

    stern_id = self.stern_id_from_url(user_row.find('a')[:href])

    return_to_connections_page

    { tag:, stern_id: }
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    end
    raise e
  end

  def remove_connection!(player)
    if player.stern_id.present?
      session.visit self.stats_page_url_for(player)
    else
      self.search_for(player.username)
    end

    if session.has_button?("Unfollow")
      session.click_button "Unfollow"
    end

    return_to_connections_page

    true
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    end
    raise e
  end

  def search_for(username)
    search_field = session.find('input', id: 'username-search')

    search_field.fill_in with: username

    search_field.sibling('button').click
  end

  def return_to_connections_page
    session.visit @default_url
  end

  def session
    # From https://github.com/heroku/heroku-buildpack-google-chrome
    chrome_bin = ENV.fetch('GOOGLE_CHROME_SHIM', nil)

    options = Selenium::WebDriver::Chrome::Options.new
    # ... I don't think this does anything
    options.binary = chrome_bin if chrome_bin

    # Discovered this by spelunking in the webdrivers code. I'm not really sure
    # how all these gems interact...
    Selenium::WebDriver::Chrome.path = chrome_bin if chrome_bin

    if ENV["SHOW_CHROME_UI"].nil? || ENV["SHOW_CHROME_UI"] == "0"
      # Comment out for debugging (or set the envvar to 1)
      options.add_argument('--headless')
    end

    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(
         app,
         browser: :chrome,
         options: options
      )
    end

    @session ||= Capybara::Session.new(:chrome) do |config|
      config.run_server = false
      config.app_host = 'https://insider.sternpinball.com/'
      config.default_max_wait_time = 5
    end
  end

  def quit
    @session.quit
    @session = nil
  end
end
