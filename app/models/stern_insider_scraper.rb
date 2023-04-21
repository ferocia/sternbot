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

    score = session.find('th', text: 'HIGH SCORE')
      .send(:parent) # tr
      .send(:parent) # thead
      .send(:parent) # table
      .find('tbody')
      .find('tr')        # Only one row in this table
      .find_all('td')[1] # Second column
      .text

    session.go_back
    session.go_back

    {
      high_score: score.gsub(/[^0-9]/, "").to_i
    }
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    else
      raise e
    end
  end

  def add_connection!(username)
    session.fill_in 'Search', with: username

    # Button text changes depending on browser width :cool:
    if session.has_button?("Search")
      session.click_button "Search"
    else
      session.click_button "Go"
    end
    tag = session
      .find('span', text: username)
      .send('parent') # div
      .find('p.uppercase')
      .text
    if session.has_button?("Follow")
      session.click_button "Follow"
    end
    session.go_back
    tag
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    else
      raise e
    end
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
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    else
      raise e
    end
  end

  def session
    # Switch to :selenium_chrome to debug non-headless
    @session ||= Capybara::Session.new(:selenium_chrome_headless) do |config|
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
