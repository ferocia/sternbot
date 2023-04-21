# Stern Stats

An app to scrape player stats fom Stern Insider Connected.

## Data Model

Insider Connected doesn't give us match history, which is annoying. We store
every new observation of a high score, which gives us fake history.

## Maintenance

The action happens in a background job that re-enqueues itself on completion. To kick this off for the first time, with a one minute delay between runs:

    SyncJob.perform_later(1.minute)

To remove this job:

    GoodJob::Job.all.each(&:destroy)
