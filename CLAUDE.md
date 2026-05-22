# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`solid_queue_web` is a mountable Rails engine (published as a gem) that provides a web dashboard for [Solid Queue](https://github.com/rails/solid_queue). It has no host application — development and testing both use the dummy Rails app under `spec/dummy/`.

## Commands

```bash
# Run the full suite (rubocop + rspec) — this is what CI runs
bundle exec rake

# Run only tests
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/requests/solid_queue_web/jobs_spec.rb

# Run a single example by line number
bundle exec rspec spec/requests/solid_queue_web/jobs_spec.rb:42

# Lint
bin/rubocop

# Set up and seed the development database (dummy app)
bundle exec rake dev:setup   # creates and migrates spec/dummy/db/development.sqlite3
bundle exec rake dev:seed    # populates with realistic fake jobs/processes

# Reset dev database (setup + seed)
bundle exec rake dev:reset

# Start the dummy app for manual testing
cd spec/dummy && bin/rails server
# Dashboard is at http://localhost:3000/jobs
```

## Architecture

### Engine isolation

The engine uses `isolate_namespace SolidQueueWeb`, so all routes, controllers, helpers, and models live under that namespace. The engine requires no database migrations of its own — it reads directly from the host app's Solid Queue tables via `SolidQueue::*` models (a declared gem dependency).

### Execution model pattern

Solid Queue represents job state with separate execution tables. Each status maps to a distinct ActiveRecord model:

| Status      | Model                              |
|-------------|------------------------------------|
| `ready`     | `SolidQueue::ReadyExecution`       |
| `scheduled` | `SolidQueue::ScheduledExecution`   |
| `claimed`   | `SolidQueue::ClaimedExecution`     |
| `blocked`   | `SolidQueue::BlockedExecution`     |
| `failed`    | `SolidQueue::FailedExecution`      |

`JobsController` maps the `?status=` param to these models via `EXECUTION_MODELS`. Only `ready`, `scheduled`, and `blocked` jobs can be discarded from the jobs list (`DISCARDABLE`); failed jobs have their own `FailedJobsController` with retry/discard.

### No asset pipeline dependency

CSS is delivered entirely via the `inline_styles` helper, which reads `application.css` at request time and injects it as a `<style>` tag. This prevents conflicts when mounted in any host app. There is no JavaScript — queue pause/resume and job discard use standard form POSTs or Turbo Stream responses.

### Turbo Stream responses

`JobsController#destroy` responds to both HTML and `turbo_stream` format. When a job is discarded:
- If more jobs remain in the filtered scope → removes that row from the DOM.
- If it was the last job → replaces the table with an empty-state element (`sqd-empty`).

### Authentication

`SolidQueueWeb.authenticate` stores a single block (set via an initializer in the host app). `ApplicationController#authenticate!` runs that block in controller context via `instance_exec`. If the block returns falsy, it falls back to HTTP Basic auth. No auth is enforced by default.

### Pagination

Pagy is included via `Pagy::Method` (not `Pagy::Backend`) and configured globally in the engine initializer with a limit of 25.

### Test setup

`spec/rails_helper.rb` loads `spec/dummy/db/schema.rb` directly on every test run (no migrations). Tests are all request specs that hit the dummy app's mounted engine at `/jobs`. Factories are not used — records are created directly with `SolidQueue::*` models.

### Releasing

`bin/release <version>` — bumps the version file, updates `Gemfile.lock` and `CHANGELOG.md`, commits, tags, and pushes. CI picks up the tag and publishes to RubyGems via Trusted Publishing. Must be run from `main` with a clean working tree.

### CHANGELOG conventions

- New entries go under `## [Unreleased]` on the feature branch, before opening a PR.
- Sections within each version must appear in this order: `### Added`, `### Changed`, `### Fixed`. Omit sections that have no entries — never add an empty section header.
- Branch workflow: always commit on a `feat/*` or `chore/*` branch; never commit directly to `main`.
