# Sternbot

An app to scrape player stats fom Stern Insider Connected.

## Synopsis

This bot responds to Slack commands:

```
:pinball: players
:pinball: leaderboard
:pinball: add some_username
:pinball: remove some_username
```

## Data Model

Insider Connected doesn't give us match history, which is annoying. We store
every new observation of a high score, which gives us fake history.

## Maintenance

The action happens in a background job that re-enqueues itself on completion.
To kick this off for the first time, with a one minute delay between runs:

    SyncJob.perform_later(1.minute)

To remove this job:

    GoodJob::Job.all.each(&:destroy)

This should be redone to use GoodJob's cron mechanism, right now it's fragile
because in some cases (deploys, unexpected failure) the job can die and not
reschedule itself.
