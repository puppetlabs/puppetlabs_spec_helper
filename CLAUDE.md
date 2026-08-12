# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this gem is

`puppetlabs_spec_helper` is a shared library, not a standalone app. Puppet modules (e.g. stdlib, firewall) add it as a dev dependency to get: Rake tasks for testing/linting/fixture management, and a `spec_helper.rb` that initializes Puppet/rspec-puppet correctly across many Puppet versions. Consuming modules `require` files from `lib/puppetlabs_spec_helper/` and load `rake_tasks.rb` from their own Rakefile — this repo's own Rakefile/spec suite exists to test that behavior in isolation (see `spec/unit/` and `spec/acceptance/fixtures/Rakefile`, which simulates a consuming module).

## Commands

```
bundle exec rake spec              # run unit tests (spec/unit)
bundle exec rake spec:coverage     # unit tests with SimpleCov coverage report (coverage/)
bundle exec rspec spec/unit/puppetlabs_spec_helper/tasks/fixture_helpers_spec.rb   # single file
bundle exec rspec spec/unit/puppetlabs_spec_helper/tasks/fixture_helpers_spec.rb -e "some example description"  # single example

bundle exec rake acceptance        # acceptance tests (spec/acceptance) — exercises the real Rake tasks against a fixture module
bundle exec rake rubocop           # lint this gem's own Ruby code
bundle exec rake yard              # build YARD docs
```

There is no top-level default `rake` task pointed at `spec` — `task default: [:help]` in `rake_tasks.rb` just lists tasks. Use `bundle exec rake spec` explicitly.

Ruby >= 3.1 is required (gemspec). CI runs against Ruby 3.2/3.3 (see `.github/workflows/ci.yml`).

## Architecture

Two distinct surfaces are shipped from `lib/puppetlabs_spec_helper/`, and most of the complexity is in keeping them decoupled from any specific Puppet/RSpec version:

- **Rake tasks** (`rake_tasks.rb`) — loaded by a consuming module's `Rakefile` via `require 'puppetlabs_spec_helper/rake_tasks'`. Defines `spec`, `spec_prep`, `spec_clean`, `parallel_spec`, `lint`, `validate`, `check`, `release_checks`, etc. Optional gems (`metadata-json-lint`, `puppet_blacksmith`, `github_changelog_generator`, `puppet-strings`, `parallel_tests`, `rubocop`) are all `require`d inside `begin/rescue LoadError` guards — the tasks degrade gracefully (raise a clear error or emit a warning) when those gems aren't in the consumer's Gemfile. Don't add a hard dependency without that guard pattern.
- **Fixture management** (`tasks/fixtures.rb`, module `PuppetlabsSpecHelper::Tasks::FixtureHelpers`) — parses `.fixtures.yml`, and downloads/symlinks dependent modules into `spec/fixtures/modules` for `spec_prep`. Repos and forge modules download in parallel via manually-managed `Thread`s (`download_items`, capped by `MAX_FIXTURE_THREAD_COUNT`), not a thread pool library — see `current_thread_count`/`redo` loop before touching this. This module is `include`d at the top level (`include PuppetlabsSpecHelper::Tasks::FixtureHelpers`) so its methods act as Rake DSL helpers.
- **Spec helpers** (`puppet_spec_helper.rb`, `module_spec_helper.rb`, `puppetlabs_spec_helper.rb`, `puppetlabs_spec/*.rb`) — loaded by a consuming module's `spec_helper.rb`. `puppet_spec_helper.rb` is the version-compatibility-hack layer (see its own header comment) that initializes Puppet's TestHelper API across Puppet versions; `module_spec_helper.rb` layers rspec-puppet + fixture path/env setup on top; `puppetlabs_spec/` provides `Files`, `Fixtures`, and `Matchers` mixins exposed to consumer specs via `RSpec.configure`.

Load order matters: `puppetlabs_spec_helper.rb` requires the `puppetlabs_spec/*` mixins and configures RSpec; `puppet_spec_helper.rb` requires that file then adds Puppet-specific logging/mock setup; `module_spec_helper.rb` requires `puppet_spec_helper.rb` then adds rspec-puppet config. Consumers typically require only one of these three, not all.

Because this gem must support many Puppet/Ruby versions simultaneously, avoid depending on gems in the gemspec that aren't available across all supported Rubies (see `CONTRIBUTING.md` and the README's "Running on non-current ruby versions" section) — anything version-sensitive belongs in the Gemfile behind a `rescue LoadError`, following the existing pattern in `rake_tasks.rb`.

## Hard Constraints

- At the start of a coding session, review the repository structure and any relevant README or documentation files to understand the area you are working in.
- Always read the files relevant to the task before suggesting or making a change.
- Never merge a pull request.
- Never work directly on the `main` or `master` branch.
- Never push a branch without explicit instruction.
- Never delete a file without permission — this applies even after a blanket "yes to all".
- Never output, log, save, or hardcode security-sensitive values — this includes passwords, tokens, API keys, private keys, secrets, and credentials of any kind. Do not write them to files, include them in commit messages, or print them in responses.

## Testing this repo's own code

- `spec/spec_helper.rb` loads `fakefs/spec_helpers` and patches `FakeFS::Pathname#symlink?` — Rake-task specs run against a fake filesystem (`RSpec.shared_context 'with a rake task', type: :task` sets this up automatically for specs whose top-level description starts with `rake `).
- `spec/acceptance/` runs the packaged Rake tasks for real against `spec/acceptance/fixtures/Rakefile`, which stands in for a consumer module's Rakefile.
- `voxpupuli-rubocop` config is inherited in `.rubocop.yml`; `.rubocop_todo.yml` tracks pre-existing violations not yet fixed — don't add new ones.
