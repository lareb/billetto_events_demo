# Billetto Events Demo

A Rails app that pulls events from the Billetto API, lists them, and lets
signed-in users upvote or downvote each one. Votes are stored as domain events
in Rails Event Store; an async read model keeps the counts shown on the page.

## Setup

### Prerequisites

- Ruby 3.2+
- PostgreSQL 14+ running locally
- Chrome (only for the browser specs)

### Install

```bash
bundle install
bin/rails db:create db:migrate
```

The database config defaults to `postgres`/`postgres` on localhost. Override
with `DATABASE_USERNAME`, `DATABASE_PASSWORD` and `DATABASE_HOST` if yours
differ.

### Credentials (optional — the app runs without them)

Billetto API key pair, from your organiser account under
Integrate → Developers:

```bash
bin/rails credentials:edit
# billetto:
#   api_id: "..."
#   api_secret: "..."
```

Clerk, from your application's API Keys page:

```bash
export CLERK_PUBLISHABLE_KEY=pk_test_xxx
export CLERK_SECRET_KEY=sk_test_xxx
export CLERK_SIGN_IN_URL=https://your-app.accounts.dev/sign-in
export CLERK_SIGN_UP_URL=https://your-app.accounts.dev/sign-up
export CLERK_SIGN_OUT_URL=https://your-app.accounts.dev/sign-out
```

Without either set the app still runs — see [Fallbacks](#fallbacks) below.

### Run

```bash
bin/rails db:seed      # or: bin/rails events:ingest
bin/rails server
```

Then open http://localhost:3000.

### Test

```bash
bundle exec rspec
```

34 examples covering the `Event` model validations, the Billetto adapter's HTTP
error handling (stubbed with WebMock), the auth gate on voting, the vote events
and read model, and three browser specs driving real headless Chrome through
sign-in, voting and sign-out.

## Rails Event Store setup

Installed with the `rails_event_store` gem. Three pieces:

**1. Tables.** Generated with

```bash
bin/rails generate ruby_event_store:active_record:migration
bin/rails db:migrate
```

which creates `event_store_events` and `event_store_events_in_streams`.

**2. Client.** `config/initializers/rails_event_store.rb` builds the client and
registers subscriptions:

```ruby
Rails.configuration.event_store = RailsEventStore::Client.new
ApplicationSubscriptions.subscribe!(Rails.configuration.event_store)
```

The default client dispatches ActiveJob subscribers after the surrounding
transaction commits, and runs plain-object subscribers synchronously.

**3. Subscriptions.** Each domain module exposes `self.subscriptions`, and
`lib/application_subscriptions.rb` merges them:

```ruby
module Votes
  def self.subscriptions
    {
      Votes::EventUpvoted => [ VoteCountJob ],
      Votes::EventDownvoted => [ VoteCountJob ]
    }
  end
end
```

Events are `Fact` subclasses (`app/domain/fact.rb`) declaring a `SCHEMA` and
the stream they belong to:

```ruby
class EventUpvoted < Fact
  SCHEMA = { event_id: Integer, user_id: String, previous_direction: String }.freeze

  def stream_names
    [ "Event$#{data.fetch(:event_id)}" ]
  end
end
```

One stream per event, so a single event's vote history reads back with:

```bash
bin/rails runner 'pp Rails.configuration.event_store.read.stream("Event$1").to_a'
```

Because `vote_counts` is derived state, it can be rebuilt from the stream at
any time by replaying those facts through `VoteCountJob`.

## Design notes

Structure follows the team's Developer's Guide: domain logic under
`app/domain/<module>/`, controllers that only build a command and hand it to the
command bus (`lib/command.rb`), state changes published as facts, and display
data served by a read model.

- `app/domain/events/` — the `Event` model plus `IngestFromBilletto`. Plain
  CRUD; ingestion isn't a business event here so it publishes nothing.
- `app/domain/votes/` — the event-sourced part. `CastVote` → `Votes::Service` →
  publishes `EventUpvoted` / `EventDownvoted`.
- `app/jobs/vote_count_job.rb` — subscribes to those facts on the `low` queue
  and maintains the `vote_counts` read model in `app/read_models/`.
- `app/integrations/billetto/` — API wrapper, with a fake adapter for tests and
  credential-less runs.

A user gets one vote per event, backed by a unique index on
`(event_id, user_id)`. Changing a vote updates that row and publishes a new
fact; the read model moves the count between buckets. Clicking the same
direction twice is a no-op — without that guard the count climbs on every
click.

### Fallbacks

**Billetto.** With no API credentials the app uses `Billetto::FakeAdapter` and
its three sample events, so the listing page is never empty. If the real API
call fails, `Events::Service` logs it and leaves existing events alone rather
than raising.

The endpoint path in `Billetto::Adapter` is a best guess — I didn't have an
account to confirm the real path or response shape against. It's overridable
with `BILLETTO_API_PATH`, and `Events::EventMapper` checks a few likely key
spellings so a renamed field doesn't break ingestion outright.

**Clerk.** Clerk's middleware raises without credentials, even on anonymous
requests, so with no keys set the app skips it (`CLERK_SKIP_RAILTIE`) and uses a
stub session instead — `TestSessionsController` sets a cookie that
`ApplicationController#stub_clerk_session` reads. The test suite always uses
this path so it never depends on reaching Clerk. With real keys the middleware
and the hosted sign-in/up/out URLs take over.

Worth flagging: I built and tested the Clerk path against the stub only. The
real middleware wiring follows the SDK's Rails integration but I haven't
exercised it against a live Clerk instance.

## Assumptions

- One vote per user per event, changeable rather than additive.
- Ingestion is pull-based (`bin/rails events:ingest`) rather than webhook-driven.
- Event images are stored as the URL Billetto returns, not mirrored locally.
- No `app/integrators/` process manager — voting doesn't cross module
  boundaries yet. That's where a cross-module reaction would go.
- No `ObjectRepository` / typed-id lookup from the Developer's Guide; at this
  size plain ActiveRecord finders are enough.
