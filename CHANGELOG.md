# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Recurring task list — `GET /recurring_tasks` enumerates all `SolidQueue::RecurringTask` records with key, cron schedule, job class or command, queue, next-run time, last-run time, and static/dynamic badge; each row has a "Run Now" button that immediately enqueues the task via `RecurringTasks::RunsController`; "Recurring" link added to the queue subnav
- Job history view — `GET /history` lists all finished jobs with class name, queue, duration, and finished-at time; filterable by queue, class substring, and time period (1h / 24h / 7d); clicking a queue badge filters the history to that queue; CSV export respects active filters; "History" link added to the queue subnav
- Scheduled job management — "Run Now" and offset buttons (+1h / +24h / +7d) on each scheduled job row; Turbo Stream removes the row on run-now and updates the scheduled-at cell on offset reschedule; "Run All Now (N)" header button back-dates all matching scheduled executions; backed by `ScheduledJobsController` using standard CRUD (`update` for single, `create` for bulk via `run_all_now` collection route)

## [0.2.0] - 2026-05-25

### Added

- Edit arguments and retry — failed job detail page (`/failed_jobs/:id`) with full error info, backtrace, and a monospace JSON editor; submitting the editor updates the job's arguments and immediately retries it via `FailedJobs::ArgumentsController`
- Stimulus via importmap-rails — `importmap-rails` added as an engine dependency; a `selection_controller.js` manages checkbox state, select-all toggling, and form injection at submit time; JS is delivered via the host app's importmap with no asset pipeline coupling
- Bulk retry and discard for failed jobs — checkbox column on the failed jobs list; "Retry Selected" and "Discard Selected" buttons appear in a selection bar when one or more jobs are checked; backed by `FailedJobs::SelectionsController` with `POST /failed_jobs/selection` (retry) and `DELETE /failed_jobs/selection` (discard)
- Bulk selection and discard — checkbox column on the jobs list for ready, scheduled, and blocked statuses; "Discard Selected" submits only the checked jobs via `DELETE /jobs/selection` (`Jobs::SelectionsController#destroy`); "Select All" header checkbox toggles all rows; filter state is preserved in the redirect after a bulk discard
- Discard All — "Discard All (N)" button on the jobs index header discards every job matching the current filters (class, queue, priority, period) in one request; respects the discardable-status guard so claimed jobs cannot be bulk-discarded; route `POST /jobs/discard_all` merges into the existing `destroy` action branching on `params[:id]`
- CSV export — "Export CSV" button on jobs and failed-jobs index pages; export respects active filters so operators download exactly what they see on screen; columns: `id, class_name, queue_name, status, priority, enqueued_at` for jobs and `id, class_name, queue_name, error_class, error_message, failed_at` for failed jobs
- Job detail page — `jobs/:id` show view with full arguments (pretty-printed JSON), queue, priority, enqueued time, status badge, Active Job ID, and status-specific metadata (scheduled_at, concurrency key, blocked-until); job class in the list is now a link to the detail page; Discard button available on the detail page for ready, scheduled, and blocked jobs
- Job filtering — filter the jobs list by queue name, job class (substring), priority, and time period (1h / 24h / 7d / all) via query-param driven scopes; active filters are preserved across status tabs
- Job filter Turbo Frame — filter form and results table wrapped in a `<turbo-frame>` so applying filters reloads only the table without a full page refresh; `data-turbo-action="advance"` keeps the URL in sync

### Fixed

- Retry button on failed jobs raised `NoMethodError` when dev seed data stored arguments as a raw JSON string instead of a Hash; seeds now use the Active Job arguments format (`executions`, `exception_executions` keys) that `SolidQueue::Job#reset_execution_counters` requires
- Action buttons in table rows were stacking vertically because `button_to` wraps each button in a block-level `<form>`; fixed with `.sqw-actions form { display: inline }`
- `FailedJobsController#destroy` used a local variable instead of `@execution`, making the Turbo Stream row-removal template a no-op
- Failed jobs index rendered error as a string via `.lines` — SolidQueue serializes `error` as JSON; now uses `execution.exception_class`
- Replaced deprecated Rack status `:unprocessable_entity` with `:unprocessable_content`

## [0.1.0] - 2026-05-24

### Added

- Overview dashboard with live stats across Solid Queue, Solid Cache, and Solid Cable
- Solid Queue job monitoring: filterable list by status (ready, scheduled, claimed, blocked) with paginated results
- Solid Queue failed jobs: dedicated view with per-job retry and discard actions
- Queue management: pause and resume individual queues
- Worker process list showing all registered Solid Queue processes
- Solid Cache monitoring: entry count and total byte size
- Solid Cable monitoring: message count and active channel count
- Turbo Stream job discard: removes the row inline, or replaces the table with an empty state when the last job is discarded
- Authentication hook — configure via `SolidQueueWeb.authenticate { |controller| ... }` in an initializer; falls back to HTTP Basic if the block returns falsy
- Configurable page size via `SolidQueueWeb.page_size` (default: 25)
- Inline CSS delivery — no asset pipeline dependency, safe to mount in any host app
- Two-tier contextual navigation per section (Queue / Cache / Cable)
- No runtime JavaScript dependency — all interactions use standard form POSTs or Turbo Stream

[Unreleased]: https://github.com/eclectic-coding/solid_stack_web/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.1.0
