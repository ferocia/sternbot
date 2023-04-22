class SyncJob < ApplicationJob
  queue_as :default

  def perform(recur_after)
    Syncer.sync!(notify: true)
    if recur_after
      self.class.set(wait: recur_after).perform_later(recur_after)
    end
  end
end
