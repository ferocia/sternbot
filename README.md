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

The action happens in a background job (`SyncJob`) that is scheduled using Good Job's cron.
