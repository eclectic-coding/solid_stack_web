# SolidStackWeb

[![CI](https://github.com/eclectic-coding/solid_stack_web/actions/workflows/ci.yml/badge.svg)](https://github.com/eclectic-coding/solid_stack_web/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/solid_stack_web.svg)](https://badge.fury.io/rb/solid_stack_web)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-ruby)](https://www.ruby-lang.org)
[![codecov](https://codecov.io/gh/eclectic-coding/solid_stack_web/branch/main/graph/badge.svg)](https://codecov.io/gh/eclectic-coding/solid_stack_web)

A mountable Rails engine that provides a unified web dashboard for the full [Solid Stack](https://github.com/rails/solid_queue) — **Solid Queue**, **Solid Cache**, and **Solid Cable** — in a single interface with no asset pipeline dependency and no JavaScript runtime requirement.

## Features

- **Overview dashboard** with live counts across all three Solid Stack components; cards are clickable and link directly to each section
- **Solid Queue** — browse jobs by status (ready, scheduled, claimed, blocked) with filtering by job class, queue name, priority, and time period; manage failed jobs (retry / discard / bulk retry / bulk discard), pause/resume queues, and inspect worker processes; **Bulk selection** checkbox-selects individual jobs for discard or retry; **Discard All** bulk-discards every job matching the current filters in one request; **CSV export** downloads jobs or failed jobs as a CSV file respecting active filters
- **Job detail page** — drill into any job to see full arguments (pretty-printed JSON), queue, priority, enqueued time, Active Job ID, concurrency key, scheduled/blocked-until metadata, and a Discard button
- **Solid Cache** — entry count and total byte size at a glance
- **Solid Cable** — active message count and distinct channel count
- **Turbo Stream** job discard — removes the row inline without a full page reload
- **Authentication hook** — plug in your own auth logic (Devise, Basic Auth, custom) via a one-line initializer
- **Zero asset pipeline coupling** — CSS is injected inline; safe to mount in any host app

## Installation

Add the gem to your application's `Gemfile`:

```ruby
gem "solid_stack_web"
```

Run:

```bash
bundle install
```

Mount the engine in `config/routes.rb`:

```ruby
mount SolidStackWeb::Engine, at: "/solid_stack"
```

The dashboard will be available at `/solid_stack` (or whatever path you choose).

## Configuration

Create an initializer at `config/initializers/solid_stack_web.rb`:

```ruby
SolidStackWeb.configure do |config|
  # Number of items per paginated page (default: 25)
  config.page_size = 50

  # Authentication — block runs in controller context.
  # Return a truthy value to allow access; falsy falls back to HTTP Basic.
  config.authenticate do
    current_user&.admin?
  end
end
```

### Job Filtering

The jobs list supports four independent filters, all driven by query params:

| Param | Description |
|-------|-------------|
| `q` | Substring match against the job class name (e.g. `q=Report`) |
| `queue` | Exact queue name match; select appears only when multiple queues exist |
| `priority` | Exact priority value match; select appears only when multiple priorities exist |
| `period` | Enqueued-at window — `1h`, `24h`, `7d`, or omit for all time |

Filters are preserved when switching between status tabs (Ready / Scheduled / Running / Blocked) and when discarding a job. They can be combined freely.

### Authentication

The `authenticate` block is evaluated in the context of each request's controller instance, so any helper method available to controllers (e.g. `current_user` from Devise) works directly. If the block returns `false` or `nil`, the engine falls back to HTTP Basic authentication. If no `authenticate` block is configured, the dashboard is open.

## Requirements

- Ruby >= 3.3
- Rails >= 8.1.3
- [solid_queue](https://github.com/rails/solid_queue) >= 1.0
- [solid_cache](https://github.com/rails/solid_cache) >= 1.0
- [solid_cable](https://github.com/rails/solid_cable) >= 1.0
- [turbo-rails](https://github.com/hotwired/turbo-rails) >= 2.0

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Run the test suite: `bundle exec rake`
4. Open a pull request

Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/eclectic-coding/solid_stack_web/issues).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).