# Roadmap

`solid_stack_web` aims to be the definitive operational dashboard for the full Rails Solid Stack — a single mountable engine covering **Solid Queue**, **Solid Cache**, and **Solid Cable** with the depth needed for day-to-day production operations, not just a status page.

The path to v1.0.0 is staged: first achieve feature parity with `solid_queue_dashboard` for the queue layer, then build equivalent depth for the cache and cable layers, then unify the experience with richer interactivity and a complete test suite.

---

## v0.2.0 — Solid Queue: Core Operations

> _Make the job management layer genuinely useful for operators._

### Added
- **Bulk selection** — checkbox-driven multi-select on the jobs and failed-jobs lists
- **Bulk discard** — discard all selected jobs in a single request
- **Bulk retry (failed jobs)** — retry selected failed jobs with optional stagger interval (5 s / 10 s / 30 s / 1 m) to avoid thundering-herd restarts
- **Edit arguments & retry** — inline argument editor on failed job detail; retry with modified payload
- **CSV export** — download jobs or failed jobs as CSV (class, queue, priority, enqueued_at, error)
- **Discard all** convenience action for ready/scheduled/blocked lists

---

## v0.3.0 — Solid Queue: Scheduling, History & Recurring Tasks

> _Close the remaining Solid Queue feature gaps._

### Added
- **Scheduled job management** — reschedule a job by offset (run in +5 m / +1 h / custom) or run immediately; bulk "run all now" action
- **Job history view** — paginated list of finished (completed) jobs with duration, queue, class, and time period filter; CSV export
- **Recurring task list** — enumerate tasks defined in `config/recurring.yml` with last-run time, next-run time, and a "run now" action per task
- **Per-queue job browser** — drill into any queue from the Queues list to see its ready jobs and discard them
- **Blocked job bulk discard** — "Discard all blocked" action on the blocked jobs view

---

## v0.4.0 — Solid Queue: Analytics & Alerting

> _Give operators the data they need to detect problems before users do._

### Added
- **Performance statistics page** — per-class aggregates: execution count, average duration, p50, p95, min, max; sortable by p95
- **Slow job detection** — configurable threshold (`slow_job_threshold`); slow jobs surfaced on the dashboard and performance page
- **Dashboard stats** — add "done (1 h)", "done (24 h)", slow job count, and process health (healthy / stale) to the overview cards
- **Throughput sparkline** — 12-hour rolling bar chart of completed jobs on the dashboard
- **Queue depth sparklines** — per-queue 12-hour depth chart on the Queues index
- **Dashboard & table auto-refresh** — configurable polling intervals (`dashboard_refresh_interval`, `default_refresh_interval`) via Stimulus
- **Metrics JSON endpoint** — `GET /metrics` returns a structured payload (counts by status, throughput, process count) for external monitoring or uptime tools
- **Alert webhooks** — HTTP POST to a configurable URL when the failed-job count exceeds a threshold or a queue depth exceeds a per-queue limit; cooldown prevents alert storms
- **Configuration additions**: `slow_job_threshold`, `alert_webhook_url`, `alert_webhook_cooldown`, `alert_failure_threshold`, `alert_queue_thresholds`, `dashboard_refresh_interval`, `default_refresh_interval`, `search_results_limit`

---

## v0.5.0 — Solid Cache: Deep Monitoring

> _Move beyond a single count; give operators visibility into what's in the cache._

### Added
- **Entry browser** — paginated table of `SolidCache::Entry` records with key, byte size, created_at, and last accessed_at; sorted by size or recency
- **Key-pattern search** — filter entries by key prefix or substring
- **Size distribution stats** — top-N entries by byte size; histogram bucketed by size range
- **Entry detail** — view the serialised value of a single cache entry (with a configurable `allow_value_preview` toggle for sensitive data)
- **Delete entry** — remove a single cache entry from the browser
- **Flush actions** — "Flush expired" (entries past their TTL), "Flush all" (with confirmation prompt)
- **Cache timeline** — 24-hour chart of entry count and total byte size growth
- **Stats dashboard card** — expand the overview card to include hit/miss rates if `SolidCache` exposes them, plus oldest-entry age

---

## v0.6.0 — Solid Cable: Channel Monitoring

> _Surface what's actually flowing through Action Cable._

### Added
- **Channel browser** — list all active channels with message count, last message time, and subscriber count (where available)
- **Per-channel message list** — paginated view of recent `SolidCable::Message` records for a channel, with payload preview
- **Message search** — filter messages across channels by channel name or payload substring
- **Message purge** — delete all messages for a channel or all messages older than N days
- **Stats dashboard card** — expand the overview card to include messages per hour, oldest pending message age, and top channels by volume
- **Cable timeline** — 24-hour chart of message volume

---

## v0.7.0 — Interactivity & UX

> _Make the interface feel fast and operational, not just functional._

### Added
- **Stimulus: debounced search** — live filter results update as you type without a full page reload
- **Stimulus: bulk selection** — select-all / deselect-all checkbox management; keeps count badge updated
- **Stimulus: auto-refresh** — Turbo Frame polling for dashboard stats and job tables at configurable intervals
- **Dark mode** — Stimulus theme controller toggles a `data-theme` attribute; CSS custom properties drive both light and dark palettes; preference persisted in `localStorage`
- **Empty-state improvements** — contextual empty states per section with actionable next steps
- **Inline notifications** — flash-style Turbo Stream feedback on bulk actions
- **Responsive layout** — stats cards and tables adapt to narrow viewports

---

## v0.8.0 — Test Coverage

> _Make the test suite match the surface area of the engine._

### Added
- Request specs for every controller action (index, show, create, update, destroy) across all sections
- Service class unit tests (stats aggregation, alert webhook, metrics payload)
- Edge-case coverage: empty states, pagination boundaries, auth rejection, format variants (HTML / Turbo Stream / JSON / CSV)
- Shared request spec helpers extracted to `spec/support/`
- CI matrix coverage target raised to ≥ 90%

---

## v0.9.0 — Polish & Developer Experience

> _Make it easy to adopt and easy to contribute to._

### Added
- **Install generator** — `rails generate solid_stack_web:install` creates the initializer with all config options documented inline
- **Configurable mount path helper** — engine-aware path helpers that respect whatever `at:` the host app chose
- **Accessibility pass** — keyboard navigation, ARIA labels on interactive elements, sufficient colour contrast in both themes
- **Query optimisation** — eliminate N+1 queries across all list views; add covering indexes to the dummy app schema
- **Error pages** — engine-scoped 404/500 views so errors stay within the dashboard chrome
- **Changelog-driven upgrade notes** — `UPGRADING.md` for any breaking configuration changes

---

## v1.0.0 — Stable Release

> _Declare a stable public API and commit to semantic versioning guarantees._

### Added
- Final UI polish pass — visual consistency across all three sections
- Complete README with configuration reference, screenshot gallery, and security guidance
- Public API stability policy documented — breaking changes require a major version bump
- Deprecation warnings for any config keys renamed between 0.x and 1.0

---

## Out of Scope (for now)

- **Background job execution** — this is a monitoring engine, not a worker runner; it will never enqueue or execute jobs itself
- **Multi-app support** — one mounted instance per Rails app; cross-app aggregation is out of scope
- **Solid Queue pro features** — concurrency limits, job priorities at the process level — those belong in Solid Queue itself
- **WebSocket push** — real-time push via Action Cable is deferred; polling via Turbo Frame covers the operational need without coupling the dashboard to its own cable configuration