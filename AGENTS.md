# Repository Guidelines

## Project Structure & Module Organization
- `app/` hosts controllers, models, views, mailers, and jobs; shared concerns live in `app/models/concerns`.
- `app/javascript` carries Stimulus controllers loaded via importmap. Tailwind sources live in `app/assets/stylesheets`, with compiled output in `app/assets/builds`.
- Domain services sit in `app/services`; reusable helpers go in `lib/`.
- Database migrations and seeds live in `db/`; fixtures and integration tests mirror app paths in `test/`.

## Build, Test, and Development Commands
- `bin/setup` installs gems, prepares the database, clears logs, and restarts Rails—run after pulling new dependencies.
- `bin/dev` boots the Rails server and Tailwind watcher via Foreman (defaults to port 3000).
- `bin/rails db:migrate` applies schema changes during development and review.
- `yarn build:css` compiles Tailwind once; `yarn build:css:watch` starts a polling watcher for dev servers.
- `bin/rails test` runs the Minitest suite; scope with paths such as `bin/rails test test/models/user_test.rb`.

## Coding Style & Naming Conventions
- Follow Ruby 3.2 / Rails defaults: two-space indentation, snake_case files, CamelCase classes, and predicate methods ending in `?`.
- Keep controllers thin; move non-trivial logic into POROs or services, and share view fragments through partials or ViewComponent classes under `app/components` when introduced.
- Stimulus controllers end in `_controller.js` and register through `app/javascript/controllers/index.js`.
- Favor Tailwind utility classes in templates; add shared tokens in `app/assets/stylesheets/application.tailwind.css`.

## Testing Guidelines
- Minitest is the primary framework. Name files with `_test.rb` and mirror the structure of the code under test.
- Add unit tests for models/POROs, request tests for controllers, and system tests for full-stack flows touching Hotwire or Tailwind UI.
- Seed or fixture data first, assert the failing case, then implement; rerun relevant tests before submitting changes.

## Commit & Pull Request Guidelines
- Write imperative commit subjects under ~70 characters (e.g., `Add marketing lead import`) and include contextual bodies for schema or behavior changes.
- Squash WIP commits locally. Open PRs only after tests pass, summarizing user impact, rollout notes, and manual verification.
- Link issues or tickets in the PR, attach screenshots for UI changes, and list follow-up tasks or feature flags so reviewers know next steps.

## Environment & Configuration Notes
- Copy or create `config/database.yml` before running migrations; never commit machine-specific credentials.
- Manage secrets via `bin/rails credentials:edit` and keep the master key out of source control.
- Store local-only environment variables in a gitignored `.env.local`, and document new settings in the PR for fast setup.
