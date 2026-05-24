# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/eclectic-coding/solid_stack_web/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/eclectic-coding/solid_stack_web/releases/tag/v0.1.0
