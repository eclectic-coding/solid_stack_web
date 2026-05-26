# Roadmap

`solid_stack_web` aims to be the definitive operational dashboard for the full Rails Solid Stack — a single mountable engine covering **Solid Queue**, **Solid Cache**, and **Solid Cable** with the depth needed for day-to-day production operations, not just a status page.

The path to v1.0.0 is staged: first achieve feature parity with `solid_queue_dashboard` for the queue layer, then build equivalent depth for the cache and cable layers, then unify the experience with richer interactivity and a complete test suite.

---

## v0.9.0 — Polish & Developer Experience

> _Make it easy to adopt and easy to contribute to._

### Added
- ~~**Install generator**~~ ✓
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