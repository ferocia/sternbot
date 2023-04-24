require 'rails_helper'

# Some basic all-in-one smoke tests for the sync function. This really only
# tests internal logic. Helpful for active development but less so for ongoing
# regression: we use fake objects for both our dependent services (Stern
# Insider website and Slack) and the latter is most likely to change on us.
describe Syncer do
  def scraper
    @scraper ||= instance_double(SternInsiderScraper).tap do |x|
      allow(x).to receive(:login!)
      allow(x).to receive(:quit)
      allow(x).to receive(:stats_for_player).and_return({})
    end
  end

  def notifier
    @notifier ||= class_double(SlackNotifier).tap do |x|
    end
  end

  before do
    allow(Syncer).to receive(:slack_notifier).and_return(notifier)
    allow(SternInsiderScraper).to receive(:new).and_return(scraper)
    allow(LOGGER).to receive(:info)

    Player.all.each(&:destroy)
  end

  example 'add/remove player and high score syncing' do
    # it can add a player idempotently
    expect(scraper).to \
      receive(:add_connection!).with('donalias').and_return('DON')

    Syncer.add_player!('donalias')
    Syncer.add_player!('donalias')

    p = Player.find_by(tag: 'DON')
    expect(p.username).to eq('donalias')

    # it creates a new high score for player when none exists
    expect(scraper).to receive(:stats_for_player).with(p).and_return(
      high_score: 100,
      plays: 3,
      achievements: []
    )
    expect(notifier).to \
      receive(:send_message).with(/Leaderboard has changed/)

    Syncer.sync!(notify: true)
    p.reload

    expect(p.high_score).to eq(100)
    expect(p.plays).to eq(3)

    # it creates a new high score for player when higher than best
    expect(scraper).to receive(:stats_for_player).with(p).and_return(
      high_score: 110,
      plays: 4,
      achievements: []
    )
    expect(notifier).to \
      receive(:send_message).with(/Leaderboard has changed/)
    expect(notifier).to receive(:send_message).with(/personal best of 110/)

    Syncer.sync!(notify: true)
    p.reload

    expect(p.high_score).to eq(110)
    expect(p.plays).to eq(4)

    # it does not create new high score if not better
    expect(scraper).to receive(:stats_for_player).with(p).and_return(
      high_score: 90,
      plays: 6,
      achievements: []
    )

    Syncer.sync!(notify: true)
    p.reload

    expect(p.high_score).to eq(110)
    expect(p.plays).to eq(6)

    # it can remove a player idempotently
    expect(scraper).to \
      receive(:remove_connection!).with('donalias').and_return('DON')
    Syncer.remove_player!('donalias')
    Syncer.remove_player!('donalias')

    expect(Player.find_by(tag: 'DON')).to eq(nil)
  end

  example 'achievement sync' do
    # No notification on initial sync
    p = Player.create!(username: 'donalias', tag: 'DON')
    p.high_scores.create!(value: 100, observed_at: Time.zone.now)

    expect(scraper).to receive(:stats_for_player).with(p).and_return(
      high_score: 100,
      plays: 3,
      achievements: %w(skill-shot mecha-skill-shot)
    )

    Syncer.sync!(notify: true)
    p.reload

    expect(p.achievements.map(&:slug).sort).to \
      eq(%w(mecha-skill-shot skill-shot))

    # it only notifies for new achievements
    expect(scraper).to receive(:stats_for_player).with(p).and_return(
      high_score: 100,
      plays: 3,
      achievements: %w(skill-shot mecha-skill-shot secret-skill-shot)
    )
    expect(notifier).to \
      receive(:send_message).with(/DON achieved Secret Skill Shot/)

    Syncer.sync!(notify: true)
    p.reload

    expect(p.achievements.map(&:slug).sort).to \
      eq(%w(mecha-skill-shot secret-skill-shot skill-shot))

    # it updates the stern id if it retrieves one
    expect(p.stern_id).to be_nil
    expect(scraper).to receive(:stats_for_player).with(p).and_return(
      high_score: 100,
      plays: 3,
      achievements: [],
      stern_id: '1234',
    )
    Syncer.sync!(notify: true)
    p.reload

    expect(p.stern_id).to eq('1234')
  end
end
