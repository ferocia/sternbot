Capybara.threadsafe = true

class SternInsiderScraper
  def self.username
    ENV.fetch("INSIDER_USERNAME")
  end

  def login!
    session.visit '/login'

    session.fill_in 'Email', with: self.class.username
    session.fill_in 'Password', with: ENV.fetch("INSIDER_PASSWORD")

    session.click_button 'Done'

    session.click_link 'Connections'

    true
  end

  def stats_for_player(player_tag)
    session.find('a', text: player_tag).click
    session.click_link 'Godzilla'

    summary_tds = session.find('th', text: 'HIGH SCORE')
      .send(:parent) # tr
      .send(:parent) # thead
      .send(:parent) # table
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

    session.go_back
    session.go_back

    {
      high_score: score.gsub(/[^0-9]/, "").to_i,
      plays: plays.gsub(/[^0-9]/, "").to_i,
      achievements: achievements
    }
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    end
    raise e
  end

  def add_connection!(username)
    session.fill_in 'Search', with: username

    # Button text changes depending on browser width :cool:
    if session.has_button?("Search")
      session.click_button "Search"
    else
      session.click_button "Go"
    end

    # we want to match the username exactly, but allow for variations in case
    user_row = session.find('span', exact_text: /#{username}/i).ancestor('li')

    if user_row.has_button?("Follow")
      user_row.click_button "Follow"
    end

    tag = user_row.find('p.uppercase').text

    session.go_back
    tag
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    end
    raise e
  end

  def remove_connection!(username)
    session.fill_in 'Search', with: username

    # Button text changes depending on browser width :cool:
    if session.has_button?("Search")
      session.click_button "Search"
    else
      session.click_button "Go"
    end

    if session.has_button?("Unfollow")
      session.click_button "Unfollow"
    end
    session.go_back
    true
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    end
    raise e
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

    # Comment out for debugging
    #options.add_argument('--headless')

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
