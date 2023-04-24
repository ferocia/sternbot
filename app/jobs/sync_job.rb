class SyncJob < ApplicationJob
  queue_as :default

  def perform
    Syncer.sync!(notify: true)
  end
end
