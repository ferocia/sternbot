require_relative "boot"

require "rails/all"

require 'good_job/engine'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SternStats
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_job.queue_adapter = :good_job

    # Overriden in environments
    config.good_job.enable_cron = true

    config.good_job.cron = {
      # Every 3 minutes
      sync_task: {
        cron: "*/3 * * * *", # cron-style scheduling format by fugit gem
        class: "SyncJob",
        description: "Web scraper for Stern Insider"
      }
    }
  end
end
