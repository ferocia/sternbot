Capybara.threadsafe = true

class SternInsiderScraper
  def login!
    session.visit '/login'

    session.fill_in 'Email', with: ENV.fetch("INSIDER_USERNAME")
    session.fill_in 'Password', with: ENV.fetch("INSIDER_PASSWORD")

    session.click_button 'Done'

    true
  end

  def stats_for_player(player_tag)
    session.click_link 'Connections'
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
      high_score: score
    }
  rescue => e
    if Rails.const_defined?("Console")
      puts e.inspect
      binding.pry
    else
      raise e
    end
  end

  def session
    @session ||= Capybara::Session.new(:selenium_chrome) do |config|
      config.run_server = false
      config.app_host = 'https://insider.sternpinball.com/'
      config.default_max_wait_time = 10
    end
  end

end
