# Contributing

Thanks for helping improve `solid_stack_web`. Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/eclectic-coding/solid_stack_web/issues). For larger changes, open an issue first so we can agree on the approach.

## Development setup

```bash
git clone https://github.com/<you>/solid_stack_web.git
cd solid_stack_web
bin/setup
```

`bin/setup` runs `bundle install` and enables the tracked git hooks (`git config core.hooksPath .githooks`).

The engine has no host app. Development and tests use the dummy Rails app in `spec/dummy/`:

```bash
bundle exec rake dev:setup   # create and migrate the dummy app database
bundle exec rake dev:seed    # populate it with realistic fake jobs and processes
cd spec/dummy && bin/rails server   # dashboard at http://localhost:3000/jobs
```

`bundle exec rake dev:reset` runs setup and seed together.

## Running the checks

```bash
bundle exec rake            # full suite: bundler-audit, Brakeman, RuboCop, RSpec (what CI runs)
bundle exec rspec           # tests only
bundle exec rspec spec/requests/solid_stack_web/jobs_spec.rb:42   # a single example
bin/rubocop                 # lint only
bundle exec rake brakeman   # security scan only
```

A `pre-push` hook runs the full `bundle exec rake` before every push. In an emergency you can bypass it with `git push --no-verify`, but CI will still run the same checks.

If Brakeman reports a warning you have reviewed and judged a false positive, record it in `config/brakeman.ignore` with a short note explaining why.

## Pull requests

1. Fork the repository and create a branch off `main`: `feat/*` for features and fixes, `chore/*` for maintenance. Never commit directly to `main`.
2. Add or update specs. Tests are request specs against the dummy app; create records directly with `SolidQueue::*` models rather than factories.
3. For user-facing changes, add an entry to `CHANGELOG.md` under `## [Unreleased]` before opening the PR. Don't log tooling or CI changes. Use the sections `### Added`, `### Changed`, `### Fixed` in that order, and omit any section with no entries.
4. Make sure `bundle exec rake` passes, then open the PR. CI must pass (`lint`, `Brakeman`, and `test` on Ruby 3.3, 3.4, and 4.0) before it can be merged.

## Dependencies

Dependabot opens weekly update PRs. Patch and minor updates to development dependencies are merged automatically once CI passes; everything else is reviewed and merged by a maintainer. Run `bundle install` after pulling, since merged bumps change `Gemfile.lock`.

## Releasing

Maintainers only. From a clean `main`, run `bin/release <version>`. It bumps the version, updates `Gemfile.lock` and `CHANGELOG.md`, commits, tags, and pushes. CI then publishes to RubyGems via Trusted Publishing.
