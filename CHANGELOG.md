# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Slow job webhook alert — fires when the number of currently-claimed jobs exceeding `slow_job_threshold` reaches `alert_slow_job_count_threshold`; respects the shared `alert_webhook_url` and `alert_webhook_cooldown` settings; payload includes `type: "slow_jobs"`, `count`, and `threshold`
- Stale process webhook alert — fires when the number of workers with a heartbeat older than 5 minutes meets `alert_stale_process_threshold`; reuses the shared webhook URL and cooldown; payload includes `type: "stale_processes"`, `count`, and `threshold`
- Job wait time column — shows how long a claimed job waited in the queue before being picked up (time from `enqueued_at` to claim time); displayed on the claimed tab only; also included as `wait_time_seconds` in CSV exports

## [1.2.0] - 2026-05-27

### Added

- Sticky filter preferences — last-used status, period, and queue filter saved to `localStorage`; a fresh visit to `/jobs` or `/history` with no URL params restores the previous selection automatically; uses a new `filter-persist` Stimulus controller; gracefully no-ops when `localStorage` is unavailable
- Sortable columns on jobs, failed jobs, and history — server-side `?sort=&direction=` params; jobs sortable by class, queue, priority, enqueued at; failed jobs by class, queue, failed at; history by class, queue, finished at; sort state is preserved across filter and period changes

## [1.1.0] - 2026-05-27

### Added

- P99 + standard deviation columns in performance stats — `p99` and `Std Dev` columns added to the stats table; both are sortable; high std dev flags inconsistent jobs worth investigating
- Failed job trend chart — "Failures — last 12 hours" sparkline added to the Solid Queue dashboard card below the throughput sparkline; bars render in the danger color to make failure spikes immediately visible
- Error frequency report — `GET /failed_jobs/errors` groups all failed jobs by exception class and message prefix, showing count and an expandable sample backtrace per group; links through to a filtered failed jobs list via `?error_class=`; the failed jobs index gains an "Error Summary" button and shows an active-filter breadcrumb with a clear link

## [1.0.0] - 2026-05-27

### Added

- Public API stability policy — `README.md#versioning` documents what is and is not covered by semver guarantees from v1.0.0; `UPGRADING.md` cross-references the policy
- README: Security section covering authentication requirements, `allow_value_preview` caution, CSRF handling, and rate-limiting guidance
- README: Screenshots section with a single `docs/screenshots/demo.gif` slot (animated GIF showing a dashboard tour)
- README: `connects_to` added to the General configuration reference
- Deprecation warning infrastructure — `SolidStackWeb.deprecator` exposes a gem-scoped `ActiveSupport::Deprecation` instance registered with `app.deprecators`; a private `deprecated_config` helper generates forwarding writers with warnings for any config keys renamed before 1.0

### Changed

- Unify detail page layout across all three sections — cache entry detail now uses the same card-based layout as job and failed job detail pages; consolidate `sqw-detail`/`sqw-value-pre` CSS into the shared `sqw-dl`/`sqw-code-block` classes; inline margin style on the failed-job arguments card replaced with a CSS sibling-selector rule

## [0.9.0] - 2026-05-27

### Changed

- Eliminate N+1 queries on the queues index — replaced per-queue `COUNT` loop with a single `GROUP BY queue_name` aggregation
- `CacheSizeStats#buckets` now runs a single `SUM(CASE WHEN ...)` aggregation instead of one `COUNT` query per size bucket; `#total` is derived from the already-computed bucket counts (no extra query)
- `JobsController` filter options (queue and priority dropdowns) now resolved with one `pluck` call instead of two separate queries

### Added

- `UPGRADING.md` — standing upgrade guide; documents that all 0.x releases are additive with no breaking configuration changes
- Engine-scoped error pages — 404 (`ActiveRecord::RecordNotFound`) and 500 (unhandled `StandardError` in production) now render within the dashboard chrome instead of falling through to the host app's error pages; in development `consider_all_requests_local` keeps the standard Rails debug page
- Covering indexes added to dummy app schema — `solid_queue_jobs (finished_at, created_at)` for the slow-job scan; `(queue_name, created_at)` on `solid_queue_scheduled_executions` and `solid_queue_blocked_executions` (both previously lacked a queue-name index)
- Install generator — `rails generate solid_stack_web:install` creates `config/initializers/solid_stack_web.rb` with every config option documented inline and injects the mount line into `config/routes.rb`
- `SolidStackWeb.mount_path` — returns the path at which the engine is mounted in the host app, derived automatically from routes; use `link_to "Dashboard", SolidStackWeb.mount_path` to link to the dashboard without hardcoding the path
- Accessibility pass — skip-to-content link; ARIA labels on all navigation elements; `scope="col"` on every table header; visually-hidden "Actions" label on empty action-column headers; `aria-sort` on active sort columns in stats and cache entries; `aria_label: "Pagination"` on all pagination navs; `.sqw-sr-only` and `.sqw-skip-link` CSS utilities added to base stylesheet

## [0.8.0] - 2026-05-26

### Added

- Service class unit tests — model specs for `CableStats`, `CableTimeline`, `CacheStats`, `CacheSizeStats`, `CacheTimeline`, and `QueueStats`; covers zero/empty states, correct aggregation, time-window filtering, and the `slow_job_threshold` conditional
- Pagination boundary tests — `describe "pagination"` blocks added to jobs, failed jobs, cache entries, history, and cable message list specs; covers pagination controls appearing at 26+ records, page 2 returning 200, and out-of-range pages returning 200 without error
- `spec/support/request_helpers.rb` — shared `engine_root` let for all request specs; `rails_helper.rb` auto-loads `spec/support/**/*.rb`

## [0.7.0] - 2026-05-26

### Added

- Responsive layout
- Timezone-corrected timestamps — all timestamps across jobs, failed jobs, history, processes, queues, recurring tasks, cache entries, cable channels, and the dashboard are now rendered as `<time datetime="ISO8601">` elements; a `timestamp` Stimulus controller reformats each one in the browser's local timezone using `Intl.DateTimeFormat`; relative timestamps (oldest cache entry, oldest cable message, cable message list) use `Intl.RelativeTimeFormat` and expose the full local timestamp as a hover title; degrades gracefully to UTC text when JS is unavailable

### Fixed

- CSS audit — badge colours now respond to dark mode via `[data-theme="dark"]` overrides; table row hover uses `--surface-hover` CSS variable instead of a hardcoded hex value; `--surface-hover` added to `:root` and dark mode token set — stats cards, gem grid, and tables adapt to narrow viewports; two-column grids (cache size, cache timeline) collapse to single column at 768px; tables scroll horizontally at 640px; split page headers stack vertically; main padding and header padding reduce on small screens
- Empty-state improvements — all list views now show a contextual title and an actionable hint; search result empty states include a "Clear search" link; history and stats link to active jobs; processes and recurring tasks explain what to do next
- Inline notifications — bulk and single-job actions now surface a flash notice; Turbo Stream discard responses prepend the message to the page without a full reload; bulk discard/retry counts are shown ("3 jobs discarded")
- Dark mode — toggle button in the header switches between light and dark palettes; preference persisted in `localStorage`; respects `prefers-color-scheme` on first visit; driven entirely by CSS custom properties on `[data-theme="dark"]`

## [0.6.0] - 2026-05-26

### Added

- Cable timeline — 24-hour bar chart of message volume on the Solid Cable overview page; each bar represents one hour with a tooltip showing exact count; uses the `var(--info)` color token
- Cable stats dashboard card — the Solid Cable card on the overview dashboard now shows messages per hour (last 60 minutes), oldest pending message age, and a top-3 channel breakdown by message volume; Messages stat is now a link to the Cable overview
- Message purge — "Purge Old" form on the channel browser deletes all messages older than 1, 7, or 30 days; "Purge Channel" button on the per-channel message list deletes all messages for that channel; both redirect to the channel browser after purging
- Message search — channel browser (`GET /cable`) accepts `?q=` to filter the channel list by name substring; per-channel message list (`GET /cable/channels/:channel_hash`) accepts `?q=` to filter messages by payload substring; both show a contextual empty state and a Clear link when a search is active
- Per-channel message list — `GET /cable/channels/:channel_hash` shows a paginated, reverse-chronological list of `SolidCable::Message` records for a specific channel; each row shows the message ID, a truncated payload preview (120 chars), and relative sent time with exact timestamp on hover; channel names in the channel browser are now links to their message list
- Solid Cable channel browser — `GET /cable` lists all distinct channels with per-channel message count and last-message timestamp, ordered by most recent activity; a total-messages stat and channel-count stat are shown at the top; empty state shown when no messages exist; Cable subnav (Overview) added to the layout

### Fixed

- Suppress browser favicon 404 in the engine layout with an empty data URI `<link rel="icon" href="data:,">`

## [0.5.0] - 2026-05-26

### Added

- Cache timeline — Solid Cache overview page gains two side-by-side 24-hour bar charts: **Entries written per hour** and **Bytes written per hour**; each bar has a hover tooltip via the `sparkline-tooltip` Stimulus controller; backed by a `CacheTimeline` PORO (single query, bucketed in Ruby)
- Cache size distribution stats — Solid Cache overview page gains a **Size Distribution** table (5 byte-range buckets with proportional inline bars) and a **Largest Entries** table (top 10 by byte size, each linked to its detail page); both sections are hidden when the cache is empty
- Cache stats dashboard card — adds **Oldest** entry age (via `time_ago_in_words` with exact timestamp on hover) to the Solid Cache overview card; stat is hidden when the cache is empty; **Entries** count is now a link to the entry browser; `oldest_entry` added to the `/metrics` JSON payload as ISO 8601 (or `null`)
- Cache entry detail page — `GET /cache/entries/:id` shows the full key, byte size, and created-at for a single entry; value body is gated behind `SolidStackWeb.allow_value_preview` (default `false`); when enabled, displays up to 4 KB with JSON pretty-printing and a format badge (JSON / Text); entry key in the browser table is now a link to the detail page; **Delete** button on the detail page redirects back to the entry list
- Solid Cache entry browser — `GET /cache/entries` lists all `SolidCache::Entry` records in a paginated, sortable table (key, byte size, created-at); sortable by any column; key-substring search filters the list; per-row **Delete** removes a single entry; **Flush All** header button deletes every entry with a confirmation prompt; Cache subnav (Overview / Entries) added to the layout

## [0.4.0] - 2026-05-26

### Added

- Auto-refresh — dashboard, jobs, processes, and history views now poll automatically via a Stimulus `RefreshController`; refresh pauses when the browser tab is hidden or a checkbox is checked and resumes immediately on tab focus; intervals are configurable via `dashboard_refresh_interval` (default 5 s) and `default_refresh_interval` (default 10 s); `search_results_limit` (default 25) added as a configuration attribute for the upcoming search feature
- Queue depth sparklines — the Queues index gains a "Depth (12h)" column with a compact 12-hour rolling bar chart per queue; each bar is the ready-job depth at an hourly snapshot; hovering a bar shows an instant Stimulus tooltip ("N ready jobs Xh ago"); reuses the `sparkline-tooltip` Stimulus controller
- Throughput sparkline — the Solid Queue dashboard card now shows a 12-hour rolling bar chart of completed jobs; bars are hourly buckets rendered as inline SVG with `currentColor` so they respect the card's theme; zero-count buckets render at minimum height with reduced opacity; per-bar Stimulus tooltip gives instant hover feedback with exact counts and time ranges
- Alert webhooks — HTTP POST to a configurable URL when the failed-job count meets `alert_failure_threshold` or a queue's ready depth meets a per-queue limit in `alert_queue_thresholds`; a `alert_webhook_cooldown` (default 3600 s) prevents alert storms; delivery failures are swallowed so they never affect request responses; triggered on every `GET /metrics` poll
- Metrics JSON endpoint — `GET /metrics` returns a structured JSON payload with queue status counts (ready, scheduled, claimed, blocked, failed), throughput (done\_1h, done\_24h), process health (healthy, stale), optional slow\_jobs count (when `slow_job_threshold` is configured), cache entry count and byte size, cable message and channel counts, and a `generated_at` ISO 8601 timestamp; intended for external monitoring and uptime tools
- Dashboard stats — Solid Queue overview card gains "Done (1h)" and "Done (24h)" counts (linked to History with period pre-applied), "Healthy" and "Stale" process counts replacing the single Processes stat, and an optional "Slow (24h)" count (shown only when `SolidStackWeb.slow_job_threshold` is configured, linked to the Stats page); `slow_job_threshold` added to engine configuration
- Performance statistics page — `GET /stats` aggregates all finished jobs by class name and shows execution count, average duration, p50, p95, min, and max; each column header is a sort link; defaults to p95 descending so the slowest outliers appear first; duration formatting handles ms, seconds (with one decimal place), minutes, and hours; "Stats" link added to the queue subnav

### Changed

- Dashboard stat queries extracted into `QueueStats`, `CacheStats`, and `CableStats` POROs; `DashboardController#index` delegates entirely to these objects

## [0.3.0] - 2026-05-25

### Added

- Per-queue job browser — queue names and sizes on the Queues index are now links to `GET /queues/:id`, which shows a paginated list of ready jobs for that queue with job class, priority, and enqueued-at; individual "Discard" buttons remove a single job; a "Discard All Ready (N)" header button discards every ready job in the queue in one request; pause/resume controls are present on the show page so operators never need to leave the queue context
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

[Unreleased]: https://github.com/eclectic-coding/solid_stack_web/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v1.2.0
[1.1.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v1.1.0
[1.0.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v1.0.0
[0.9.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.9.0
[0.8.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.8.0
[0.7.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.7.0
[0.6.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.6.0
[0.5.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.5.0
[0.4.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.4.0
[0.3.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.3.0
[0.2.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.1.0
