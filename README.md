# Sternbot

**THIS PROJECT IS NO LONGER ACTIVE.** Stern Insider removed data from their dashboards such that there is no longer anyway to scrape the needed data.

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

The action happens in a background job (`SyncJob`) that is scheduled using Good Job's cron.

It's deployed to heroku. Some handy commands:

    heroku logs --tail

You can access admin interface at https://ferocia-sternbot.herokuapp.com/good_job

To run a sync locally for testing:

    rails console
    Syncer.sync!(notify: false)
