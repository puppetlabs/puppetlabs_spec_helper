# Previous Changes

## [2.8.0]
### Summary
This feature release adds a new rake task `parallel_spec_standalone` which is a parallel version of `spec_standalone`

### Added
- `parallel_spec_standalone` rake task
- `spec_clean_symlinks` rake task to just clean symlink fixtures, not all fixtures
- Leave downloaded fixtures on test failure to speed up test runs.
- Update already-existing fixtures instead of doing nothing to them.

## [2.7.0]
### Summary
Feature release to begin moving away from mocha as a testing (specifically, mocking) framework for modules.

### Added
- spec/plans/**/*_spec.rb to spec discovery pattern
- [mocha as default](README.md#mock_with) test framework unless explicitly set by a module

### Fixed
- parsing for test tiers in beaker rake task
- module_spec_helper compatibility with mocha 1.5.0

## [2.6.2]
### Summary
A bugfix release to remove dependency on GettextSetup.initialize() in the Rake tasks.

## [2.6.1]
### Summary
Includes changes for 2.6.0 plus tests and bugfix of said feature.

## 2.6.0 - Yanked
### Summary
Adds a `defaults` section to `.fixtures.yml` to specify properties such as `flags` that apply to all fixtures in a category. One example use case is to specify an alternate forge URI for the `forge_modules` fixtures.

### Added
- Add `defaults` section to fixtures.

## [2.5.1]
### Summary
Adds a fix to the parallel_spec rake task.

### Fixed
- In parallel_spec, warn when there are no files to test against rather than fail.

## [2.5.0]
### Summary
Adds a feature to pass test file targets from 'rake spec' to 'rspec', also fixes a parsing issue with test\_tiers.

### Added
- Allows passing test file targets through to 'rspec' from 'rake spec'.

### Fixed
- Trim whitespace from test\_tiers before parsing.

## [2.4.0]
### Summary
Fix mercurial stuff, allow fixtures other than spec/fixtures/modules/, and allow running specific tags for beaker tests.

### Added
- Ability to check out branches in mercurial
- Ability to target alternative locations to clone fixtures
- `TEST_TIERS` environment variable for beaker rake task

### Fixed
- mercurial cleanup command
- handle parallel spec load failure better

## [2.3.2]
### Summary
Cleanups and fixes around fixture handling.

### Fixed
- Do not error when no fixtures file is found or specified.
- Clean up fixtures, even if tests fail. Especially on Windows this is important to not keep lingering symlinks around.
- Fix creating of directory junctions (symlinks) on Windows for fixtures.


## [2.3.1]
### Summary
Adds a `spec_list_json` rake task

### Added
- `spec_list_json` rake task to output a module's spec tests as a JSON document

## [2.3.0]
### Added
- `CI_SPEC_OPTIONS` environment variable for `parallel_spec` rake task

### Fixed
- Remove puppet ~> 3.0 pin from gemspec

## [2.2.0]
### Summary
i18n rake task, and unbreak windows again.

### Added
- New rake task for i18n stuff.

### Fixed
- Fixture path calculation for windows
- Log to stderr instead of stdout as per rspec's spec

## [2.1.5]
### Summary:
Fix symlinks fixtures code.

## [2.1.4]
### Summary:
Better Windows support.

### Fixed:
- Create directory junctions instead of symlinks on windows (#192)
- Replace check:symlinks with platform independent alternative (#193)

## [2.1.3]
### Summary:
This release fixes puppet module install into paths with spaces, and fix conflicting build names for CI jobs.

### Fixed:
- Properly exscape paths for puppet module install
- Add "r" to the beginning of `rake compute_dev_version`

## [2.1.2]
### Summary:
The `release_tasks` now falls back to `spec` if the `parallel_spec` test fails due to the `parallel_tests` gem being absent.

### Fixed:
- Make `release_tasks` fall back to `spec` when missing the `parallel_tests` gem

## [2.1.1]
### Summary:
Bugfix for an unstated dependency on parallel\_spec that was added in 2.0.0

### Fixed:
- Add dependency for parallel\_spec, since psh requires it anyway.

## [2.1.0]
### Summary:
Minor version bump for new CI_SPEC_OPTIONS variable and bug fix.

### Added:
- use CI_SPEC_OPTIONS to pass options to rspec

### Fixed:
- an issue where gettext:setup tasks were being loaded in the wrong order within a module and causing the POT file to be created in the Puppet gem, not the module.

## [2.0.2]
### Summary:
Fixes an issue where the gettext rake tasks look in the spec\_helper and not the current module for the `locales/` directory.

## [2.0.1]
### Summary:
Fixes an issue where older puppets don't bring in the gettext gem requirement causing the psh rake tasks to fail.

### Fixed:
- Don't define gettext rake tasks if gettext library is not present

## [2.0.0]
### Summary:
This release makes the module working dir configurable, adds features for future puppet features, and updates the spec rake task for TravisCI

### Changed:
- The `release_tasks` rake task now calls `parallel_spec` instead of `spec`

### Added:
- Make `module_working_dir` configurable
- Check `type_aliases` directory for spec tests
- Locales support for i18n

### Fixed:
- Ensure /-only used on windows

## [1.2.2]
### Summary:

Dominic Cleal reported and fixed an issue with the STRICT_VARIABLES setting on puppet versions before 3.5.

## [1.2.1]
### Summary:

The previous release was taken down, as some optional gem dependencies slipped through into the gemspec, breaking builds using ruby 2.2 and earlier. This release updates the gem build process, so this should not happen again.

## [1.2.0] - 2016-08-23
### Summary:

Add a bunch of new features, and fix a bunch of annoying bugs: parallel test execution, default to strict variable checking on Puppet 4, code coverage, and rubocop tasks.

Thanks to all community contributors: Alexander Fisher, Alex Harvey, Chris Tessmer, David Moreno García, Dmitry Ilyin, Dominic Cleal, Federico Voges, Garrett Honeycutt, Leo Arnold, Matthew Haughton, Mickaël Canévet, and Rob Nelson.

### Added:

New tasks:
* Add code coverage for Ruby >= 1.9 using SimpleCov.
* Add a rubocop rake task.
* Use beaker:ssh to log into your running beaker machines.

Spec parallelization
* Add `parallel_spec` task to run specs in parallel.
* Use CI_NODE_TOTAL and CI_NODE_INDEX to split tests across nodes.

Fixtures improvements:
* Automatically symlink the module directory, if no symlink fixtures are specified.
* Add the `subdir` key to repository fixtures to only use a part of that repository.
* Set `FIXTURES_YML` environment variable to load fixtures from somewhere else than `.fixtures.yml`.

## Changed:
* Updated default excludes and rspec patterns.
* Updated default disabled lint checks to work with puppet-lint 2.0.0.
* Testing on Puppet 4 will now default to strict variable checking. Set STRICT_VARIABLES=no to disable.
* `PuppetInternals.scope` is now deprecated. Use the new `scope` property from rspec-puppet.
* beaker_nodes is now called beaker:sets.

### Fixed:
* Ignore symlinks inside .git when running check:symlinks rake task.
* Allow multiple invocations of spec_prep to run in parallel.
* Address a race condition when cloning multiple git fixtures.
* Restrict gem dependencies to work with ruby 1.9.
* Update verify_contents() to work with duplicates in the arguments.

## [1.1.1] - 2016-03-02
### Fixed:
Readded and properly deprecated the `metadata` rake task. Use the `metadata_lint` task from metadata-json-lint directly instead.

## [1.1.0] - 2016-02-25
### Summary:
This release adds the ability to clone fixtures from git in parallel, speeding
up the spec\_prep rake task.

### Added:
- Parallel fixtures cloning
- Various rake check tasks for module release preparation

### Fixed:
- Added travis ci
- Added contributing doc
- Don't validate metadata if metadata-json-lint gem is not present

## [1.0.1] - 2015-11-06
### Summary:
This bugfix release fixes the Error vs. Errno bug in 1.0.0

### Fixed:
- Raise `Errno::ENOENT` instead of `Error::ENOENT`

## [1.0.0] - 2015-11-04
### Summary:
The first 1.0 release, though the gem has been considered stable for a while.

### Added:
- `flags` value for fixtures to allow passing CLI flags when installing modules
- `spec_standalone` rake task also runs `spec/types` specs
- Can now use `.fixtures.yaml` instead of `.fixtures.yml`

### Fixed:
- Remove double-initialization that was conflicting with rspec-puppet
- Better error handling on malformed fixtures yaml
- Bug in rake task's ignore\_paths

## [0.10.3] - 2015-05-11
### Summary:
A bugfix for puppet 3 and puppet 4 tests being able to run with the same environment variables.

### Fixed:
- Allow `STRINGIFY_FACTS` and `TRUSTED_NODE_DATA` to be set on Puppet 4 as noop instead of fail
- Fix linting to be more like approved module criteria

## [0.10.2] - 2015-04-14
### Summary:
A bugfix for puppet 4 coming out, which manages modulepath and environments differently.

### Fixed:
- Use puppet 4 environmentpath and environment creation on puppet 4

## [0.10.1] - 2015-03-17
### Summary:
A bugfix for the previous release when using references.

### Fixed:
- Only shallow clone if not using a reference

## [0.10.0] - 2015-03-16
### Summary:
This release adds shallow fixtures clones to speed up the spec_prep step for
rspec-puppet

### Added:
- Shallow clone fixtures

### Fixed:
- Don't lint in vendor/ (spec/fixtures/ and pkg/ are alread ignored)
- Don't syntax check in spec/fixtures/, pkg/, or vendor/

## [0.9.1] - 2015-02-24
### Summary:
This release removes the hard dependency on metadata-json-lint, as it requires
a dev toolchain to install the 'json' gem.

### Fixed:
- Only warn when metadata-json-lint isn't installed instead of requiring it

## [0.9.0] - 2015-02-24
### Summary:
This release adds fixes for rspec-puppet 2.0 and json linting for metadata.json

### Added:
- Add json linting for metadata.json (adds dep on metadata-json-lint gem)
- Document using references in fixtures

### Fixed:
- `FUTURE_PARSER=yes` working with rspec-puppet 2.0
- Symlinks breaking on windows
- rspec as a runtime dependency conflicting with rspec-puppet
- root stub for testing execs

## [0.8.2] - 2014-10-01
### Summary:
This release fixes the lint task on the latest puppet-lint

### Fixed:
- Fix the lint task require code

## [0.8.1] - 2014-08-25
### Summary:
This release corrects compatibility with the recently-released puppet-lint
1.0.0

### Fixed:
- Turn on relative autoloader lint checking for backwards-compatibility
- Turn off param class inheritance check (deprecated style)
- Fix ignore paths to ignore `pkg/*`

## [0.8.0] - 2014-07-29
### Summary:
This release uses the new puppet-syntax gem to perform manifest validation
better than before! Shiny.

### Added:
- Use puppet-syntax gem for manifest validation rake task

### Fixed:
- Fix compatibility with rspec 3

## [0.7.0] - 2014-07-17
### Summary:
This feature release adds the ability to test structured facts, manifest
ordering, and trusted node facts, and check out branches with fixtures.

### Added:
- Add `STRINGIFY_FACTS=no` for structured facts
- Add `TRUSTED_NODE_DATA=yes` for trusted node data
- Add `ORDERING=<order>` for manifest ordering
- Add `:branch` support for fixtures on a branch.

### Fixed:
- Fix puppet-lint to ignore spec/fixtures/

## [0.6.0] - 2014-07-02
### Summary:
This feature release adds the `validate` rake task and the ability to test
strict variables and the future parser with rspec-puppet.

### Added:
- Add `validate` rake task.
- Add `STRICT_VARIABLES=yes` to module_spec_helper
- Add `FUTURE_PARSER=yes` to module_spec_helper

### Fixed:
- Avoid conflict with Object.clone
- Install forge fixtures without conflicting with already-installed modules

## [0.5.2] - 2014-06-19
### Summary:
This release removes the previously non-existant puppet runtime dependency to
better match rspec-puppet and puppet-lint and allow system puppet packages to
be used instead of gems.

### Fixed:
- Remove puppet dependency from gemspec

## [0.5.1] - 2014-06-09
### Summary:
This release re-adds mocha mocking, which was mistakenly removed in 0.5.0

### Fixed:
- Re-enable mocha mocking as default.

## [0.5.0] - 2014-06-06
### Summary:
This is the first feature release in over a year. The biggest feature is fixtures supporting the forge, and not just github, plus rake tasks for syntax checking and beaker.

### Added:
- Install modules from the forge, not just git
- Beaker rake tasks added
- Syntax task added
- Rake spec runs tests in `integration/` directory

### Fixed:
- Fix the gemspec so that this may be used with bundler
- Fix removal of symlinks
- Fix removal of site.pp only when empty
- Ignore fixtures for linting
- Remove extra mocha dependency
- Remove rspec pinning (oops)

## 0.4.2 - 2014-06-06 [YANKED]
### Summary:
This release corrects the pinning of rspec for modules which are not rspec 3
compatible yet.

### Fixed:
* Pin to 2.x range for rspec 2
* Fix aborting rake task when packaging gem
* Fix puppet issue tracker url
* Fix issue with running `git reset` in the incorrect dir

## [0.4.1] - 2013-02-08
### Fixed
 * (#18165) Mark tests pending on broken puppet versions
 * (#18165) Initialize TestHelper as soon as possible
 * Maint: Change formatting and handle windows path separator

## [0.4.0] - 2012-12-14
### Added
 * Add readme for fixtures
 * add opts logic to rake spec_clean
 * add backwards-compatible support for arbitrary git refs in .fixtures.yml

### Fixed
 * Rake should fail if git can't clone repository
 * Fix Mocha deprecations
 * Only remove the site.pp if it is empty
 * (#15464) Make contributing easy via bundle Gemfile
 * (#15464) Add gemspec from 0.3.0 published gem

## [0.3.0] - 2012-08-14
### Added
 * Add PuppetInternals compatibility module for
   scope, node, compiler, and functions
 * Add rspec-puppet convention directories to rake tasks

## [0.2.0] - 2012-07-05
### Fixed
 * Fix integration with mocha-0.12.0
 * Fix coverage rake task
 * Fix an issue creating the fixtures directory

## 0.1.0 - 2012-06-08
### Added
 * Initial release

[unreleased]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.8.0...master
[2.8.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.6.2...v2.7.0
[2.6.2]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.6.1...v2.6.2
[2.6.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.5.1...v2.6.1
[2.5.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.5.0...v2.5.1
[2.5.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.3.2...v2.4.0
[2.3.2]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.3.1...v2.3.2
[2.3.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.5...v2.2.0
[2.1.5]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.4...v2.1.5
[2.1.4]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.3...v2.1.4
[2.1.3]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.1...v2.1.2
[2.1.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v1.2.2...v2.0.0
[1.2.2]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.2.0...v1.2.1
[1.2.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.1.1...1.2.0
[1.1.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.3...1.0.0
[0.10.3]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.2...0.10.3
[0.10.2]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.1...0.10.2
[0.10.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.0...0.10.1
[0.10.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.9.1...0.10.0
[0.9.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.8.2...0.9.0
[0.8.2]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.8.1...0.8.2
[0.8.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.5.2...0.6.0
[0.5.2]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.4.1...0.5.0
[0.4.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.0.0...0.1.0
