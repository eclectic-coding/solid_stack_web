# Roadmap

`solid_stack_web` aims to be the definitive operational dashboard for the full Rails Solid Stack — a single mountable engine covering **Solid Queue**, **Solid Cache**, and **Solid Cable** with the depth needed for day-to-day production operations, not just a status page.

The project has shipped through v1.2.0, covering full Solid Queue depth — job management, queue controls, worker visibility, failed job handling, job history, sortable columns, and persistent filter preferences. The roadmap ahead deepens the observability story: configurable alerting (v1.3), opt-in audit logging (v1.4), and extensibility hooks for host apps (v2.0).

---


## v1.3 — Alerting Depth

> _More signals, fewer blind spots._

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
