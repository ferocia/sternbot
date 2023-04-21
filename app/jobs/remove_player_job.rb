class RemovePlayerJob < ApplicationJob
  queue_as :default

  def perform(username)
    Syncer.remove_player!(username)
    SlackNotifier.send_message("Removed #{username}")
  end
end
