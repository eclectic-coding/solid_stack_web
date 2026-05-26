# Roadmap

`solid_stack_web` aims to be the definitive operational dashboard for the full Rails Solid Stack — a single mountable engine covering **Solid Queue**, **Solid Cache**, and **Solid Cable** with the depth needed for day-to-day production operations, not just a status page.

The path to v1.0.0 is staged: first achieve feature parity with `solid_queue_dashboard` for the queue layer, then build equivalent depth for the cache and cable layers, then unify the experience with richer interactivity and a complete test suite.

---

## v0.4.0 — Solid Queue: Analytics & Alerting

> _Give operators the data they need to detect problems before users do._

### Added
- **Queue depth sparklines** — per-queue 12-hour depth chart on the Queues index
- **Dashboard & table auto-refresh** — configurable polling intervals (`dashboard_refresh_interval`, `default_refresh_interval`) via Stimulus
- **Configuration additions**: `dashboard_refresh_interval`, `default_refresh_interval`, `search_results_limit`

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