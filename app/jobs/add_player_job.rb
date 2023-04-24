class AddPlayerJob < ApplicationJob
  queue_as :default

  def perform(username)
    player = Syncer.add_player!(username)
    SlackNotifier.send_message("Added #{username} as #{player.tag}")
  rescue => e
    # TODO: should probably have a "why" here???
    SlackNotifier.send_message(<<~EOF)
      Failed to add #{username}.

      This is either because the username was wrong, or that user doesn't have their stats visible to the public.
      If this is you, you can go <https://insider.sternpinball.com/account/profile/stats|here> and make sure the checkbox is selected.
    EOF
  end
end
