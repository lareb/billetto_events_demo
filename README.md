# Billetto Events Demo

Rails app that pulls events from the Billetto API, lists them, and lets
signed-in users upvote or downvote each one. Votes are stored as domain events
in Rails Event Store, with a read model holding the counts shown on the page.

## Setup

Needs Ruby 3.2+, Node + Yarn, PostgreSQL 14+, and Chrome for the browser specs.

```bash
bundle install
yarn install
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
bin/dev
```

Voting and infinite scroll need the JS bundle. Use `bin/dev` (runs the Rails
server and an esbuild watcher together, per `Procfile.dev`), not
`bin/rails server` alone, or `app/assets/builds/application.js` stays empty
and those features silently fall back to plain, full-page form submits. A one-
off `yarn build` works too if you'd rather run the server by itself.

### Test

```bash
bundle exec rspec
```

43 examples: model validations, error handling against stubbed HTTP, the auth
gate on voting, the vote events and read model, and five browser specs through
headless Chrome covering sign-in/out, voting in place, and infinite scroll. No
credentials needed, including the one spec that hits the real Billetto API: it
replays a response recorded by VCR (`spec/cassettes/`) rather than making a
live call. Delete the cassette and re-run with real credentials in
`bin/rails credentials:edit` to record a fresh one.

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
- `app/integrations/billetto/` wraps the API. Tests use a recorded response
  (VCR) or an `instance_double` rather than a hand-written fake client.

One vote per event per user, backed by a unique index on `(event_id, user_id)`.
Changing a vote updates the row and publishes a new fact, and the read model
moves the count across. Clicking the same direction twice does nothing,
otherwise the count climbs on every click.

The listing paginates two ways. Billetto itself paginates (a `limit` and an
`after` cursor, `has_more`/`next_url` on each page), and `Billetto::Adapter`
follows that when ingesting, capped at `BILLETTO_API_MAX_EVENTS` as a backstop
against a runaway loop, not a product limit. The page itself loads more as you
scroll: each `events/_page` partial ends in a lazily-loaded Turbo Frame for the
next page, which nests another on arrival, and so on. No JavaScript beyond
what Turbo already ships with.

Voting works the same way, but the Turbo Frame only wraps the vote buttons
(and the error line), not the whole card. A vote re-renders just that part,
so an expanded description doesn't collapse back every time someone clicks.
`VotesController#create` renders straight back into that frame instead
of redirecting, so a vote (or an inline "sign in to vote"/validation error)
updates in place without losing your scroll position. That part specifically
isn't a redirect on purpose. Turbo's handling of a 3xx response to a
frame-scoped form submission doesn't reliably break out to a full page the way
it looks like it should (the browser's own `fetch` follows the redirect
before Turbo sees the 3xx at all), so the response needs to already match the
frame that submitted it. The controller also pins `request.format = :html`,
since Turbo tags form submissions as accepting turbo-stream and Rails would
otherwise serve the frame's HTML back with a turbo-stream content type Turbo
can't apply.

A long description is behind a native `<details>`/`<summary>` toggle, no
JavaScript. The "Read more"/"Show less" label swap and reordering the
summary to the bottom once open are both plain CSS.

Vote counts come from `vote_counts`, kept in sync by `VoteCountJob` running
asynchronously off the published fact. In development that job runs inline
(`config.active_job.queue_adapter = :inline`) rather than on Rails' default
background thread, so the count in the response Turbo renders back is never
behind the one actually in the database.

Sign-in uses Clerk's hosted pages. Sign-out is ours: Clerk has no hosted
sign-out, so `SessionsController` revokes the session over the backend API and
clears the `__session` and `__client_uat` cookies. That route is excluded from
Clerk's middleware, which redirects some requests to a handshake endpoint that
only accepts GET and turns the DELETE into a 405.

Clerk's session token is only good for about a minute, and this app doesn't
run Clerk's JS SDK to refresh it in the background, only the layout's
`<script>` tag does, loading `@clerk/clerk-js` so a vote clicked a while after
page load doesn't land on an expired token and get bounced through Clerk's
cross-origin handshake redirect instead of reaching `VotesController`.

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
- Billetto paginates with a `limit` param and an `after` cursor (`has_more` /
  `next_url` in the response). The adapter follows it, capped at 200 events
  (`BILLETTO_API_MAX_EVENTS`), since a live account had 1000+ and a demo app has
  no business mirroring the whole catalog.
- No `app/integrators/` process manager, since voting doesn't cross module
  boundaries yet.
- No `ObjectRepository` or typed-id lookup; plain ActiveRecord finders are
  enough at this size.
