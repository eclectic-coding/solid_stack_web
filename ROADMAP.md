# Roadmap

`solid_stack_web` aims to be the definitive operational dashboard for the full Rails Solid Stack — a single mountable engine covering **Solid Queue**, **Solid Cache**, and **Solid Cable** with the depth needed for day-to-day production operations, not just a status page.

The path to v1.0.0 is staged: first achieve feature parity with `solid_queue_dashboard` for the queue layer, then build equivalent depth for the cache and cable layers, then unify the experience with richer interactivity and a complete test suite. Past v1.0, the roadmap grows the dashboard into a full observability tool — error intelligence and trend charts (v1.1), daily-use UX polish (v1.2), configurable alerting (v1.3), opt-in audit logging (v1.4), and extensibility hooks for host apps (v2.0).

---

## v0.9.0 — Polish & Developer Experience

> _Make it easy to adopt and easy to contribute to._

### Remaining

_All items complete._

---

## v1.0.0 — Stable Release

> _Declare a stable public API and commit to semantic versioning guarantees._

### Added
- Final UI polish pass — visual consistency across all three sections
- Complete README with configuration reference, screenshot gallery, and security guidance
- Public API stability policy documented — breaking changes require a major version bump
- Deprecation warnings for any config keys renamed between 0.x and 1.0

---

## v1.1 — Error Intelligence

> _Surface patterns in failures, not just individual failed jobs._

- **Error frequency report** — group all failed jobs by error class + message prefix; show count and a sample backtrace; makes "ArgumentError (x212), TimeoutError (x88)" visible at a glance without clicking into each job
- **Failed job trend chart** — "Failures — Last 12 Hours" sparkline on the queue dashboard overview card; makes failure spikes visible before you click into the failed jobs list
- **P99 + standard deviation in performance stats** — extend the stats table with a 99th-percentile and std-dev column; high std dev signals inconsistent jobs worth investigating

---

## v1.2 — UX Polish

> _Quality-of-life improvements for teams using the dashboard daily._

- **Sortable columns on jobs, failed jobs, and history** — server-side `?sort=&dir=` params matching the pattern already used for cache entries and stats
- **Sticky filter preferences** — persist last-used status, period, and queue filter to `localStorage` so filter state survives page reloads

---

## v1.3 — Alerting Depth

> _More signals, fewer blind spots._

- **Slow job webhook alert** — fire when the slow-job count crosses a configurable threshold; pairs with the existing `slow_job_threshold` config — adds the alerting half
- **Process stale webhook alert** — fire when a worker's `last_heartbeat_at` expires; a worker going silent means jobs stop processing without any visible signal
- **Job wait time column** — show time from `enqueued_at` to `created_at` on claimed executions; a direct measure of queue SLA (how long jobs waited before a worker picked them up)

---

## v1.4 — Audit & Compliance

> _Requires an opt-in migration — kept separate from the no-migration-required releases above._

- **Admin audit log** — record who retried, discarded, or paused what and when; needs a `solid_stack_web_audit_events` table via an engine-provided migration (`rails solid_stack_web:install:migrations`); identity comes from the `authenticate` block; CSV export included

---

## v2.0 — Extensibility

> _Breaking changes or large architectural additions._

- **i18n / locale support** — wrap all user-visible strings in `I18n.t`; makes the gem usable for non-English apps
- **Custom dashboard cards** — registration hook so host apps can inject their own stat cards alongside the built-in queue, cache, and cable cards
- **Custom nav links** — `config.nav_links = [{ label: "Admin", url: "/admin" }]` to integrate the dashboard into the host app's navigation

---

## Out of Scope (for now)

- **Background job execution** — this is a monitoring engine, not a worker runner; it will never enqueue or execute jobs itself
- **Multi-app support** — one mounted instance per Rails app; cross-app aggregation is out of scope
- **Solid Queue pro features** — concurrency limits, job priorities at the process level — those belong in Solid Queue itself
- **WebSocket push** — real-time push via Action Cable is deferred; polling via Turbo Frame covers the operational need without coupling the dashboard to its own cable configuration