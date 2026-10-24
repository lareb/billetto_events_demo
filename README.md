# Billetto Events Demo

Rails app that pulls events from the Billetto API, lists them, and lets
signed-in users upvote or downvote each one. Votes are stored as domain events
in Rails Event Store, with a read model holding the counts shown on the page.

## Setup

Needs Ruby 3.2+, PostgreSQL 14+, and Chrome for the browser specs.

```bash
bundle install
bin/rails db:create db:migrate
```

Database defaults to `postgres`/`postgres` on localhost; override with
`DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_HOST`.

### Credentials

```bash
bin/rails credentials:edit
```

```yaml
billetto:
  api_id: "..."
  api_secret: "..."

clerk:
  publishable_key: "pk_test_..."
  secret_key: "sk_test_..."
  sign_in_url: "https://your-app.accounts.dev/sign-in"
  sign_up_url: "https://your-app.accounts.dev/sign-up"
```

Clerk's keys are on the dashboard under Configure > API Keys, the portal URLs
under Account Portal. Note the portal host has no `.clerk` in it, unlike the
Frontend API URL on the same page.

Editing these needs `config/master.key`, which isn't in the repo. Both blocks
fall back to environment variables (`BILLETTO_API_ID`, `CLERK_SECRET_KEY` and
so on) if you'd rather not set up credentials. Billetto is optional, Clerk
isn't: without its keys the app raises at boot.

### Run

```bash
bin/rails db:seed      # or: bin/rails events:ingest
bin/rails server
```

### Test

```bash
bundle exec rspec
```

35 examples: model validations, error handling against stubbed HTTP, the auth
gate on voting, the vote events and read model, and four browser specs through
headless Chrome. No credentials needed, including the one spec that hits the
real Billetto API: it replays a response recorded by VCR
(`spec/cassettes/`) rather than making a live call. Delete the cassette and
re-run with real credentials in `bin/rails credentials:edit` to record a fresh
one.

`HEADLESS=false` runs the browser specs in a visible window, `SLOWMO=1.5` adds a
pause after each click.

## Rails Event Store

Tables come from the gem's generator:

```bash
bin/rails generate ruby_event_store:active_record:migration
```

`config/initializers/rails_event_store.rb` builds the client and registers
subscriptions. Each domain module exposes `self.subscriptions` and
`lib/application_subscriptions.rb` merges them, so adding a module means adding
one merge there.

Events subclass `Fact` (`app/domain/fact.rb`) with a `SCHEMA` and the stream
they belong to. Votes go to one stream per event, `Event$<id>`, so a single
event's history reads back with:

```bash
bin/rails runner 'pp Rails.configuration.event_store.read.stream("Event$1").to_a'
```

`vote_counts` is derived, so it can be rebuilt from those facts at any time.

## Design notes

Laid out the way the Developer's Guide describes: domain logic under
`app/domain/<module>/`, controllers that build a command and hand it to the bus
(`lib/command.rb`), state changes published as facts, display data from a read
model.

- `app/domain/events/` holds the `Event` model and `IngestFromBilletto`. Plain
  CRUD, since ingestion isn't a business event here.
- `app/domain/votes/` is the event-sourced half: `CastVote` goes to
  `Votes::Service`, which publishes `EventUpvoted` or `EventDownvoted`.
- `app/jobs/vote_count_job.rb` subscribes to those on the `low` queue and keeps
  `vote_counts` up to date.
- `app/integrations/billetto/` wraps the API, with a fake adapter for tests.

One vote per event per user, backed by a unique index on `(event_id, user_id)`.
Changing a vote updates the row and publishes a new fact, and the read model
moves the count across. Clicking the same direction twice does nothing,
otherwise the count climbs on every click.

Sign-in uses Clerk's hosted pages. Sign-out is ours: Clerk has no hosted
sign-out, so `SessionsController` revokes the session over the backend API and
clears the `__session` and `__client_uat` cookies. That route is excluded from
Clerk's middleware, which redirects some requests to a handshake endpoint that
only accepts GET and turns the DELETE into a 405.

Tests fake the session rather than driving Clerk's hosted pages, which sit on
another domain behind an emailed code. `ApplicationController#stub_clerk_session`
reads a user id off a cookie the specs set themselves, and is only wired up when
`Rails.env.test?`.

## Assumptions

- One vote per user per event, changeable rather than additive.
- Ingestion is pull-based rather than webhook-driven.
- Event images are stored as the URL Billetto returns, not mirrored.
- `Billetto::Adapter` defaults to `GET /api/v3/public/events` on `billetto.dk`,
  matching a live account. `EventMapper` also tries a couple of older key
  spellings, so one renamed field won't break ingestion outright.
- No `app/integrators/` process manager, since voting doesn't cross module
  boundaries yet.
- No `ObjectRepository` or typed-id lookup; plain ActiveRecord finders are
  enough at this size.
