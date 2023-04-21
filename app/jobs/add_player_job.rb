class AddPlayerJob < ApplicationJob
  queue_as :default

  def perform(username)
    player = Syncer.add_player!(username)
    SlackNotifier.send_message("Added #{username} as #{player.tag}")
  end
end
