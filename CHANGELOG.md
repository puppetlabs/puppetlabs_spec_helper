# Change log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

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

[unreleased]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.1.1...master
[1.2.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.2.1...1.2.2
[1.2.1]: https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.2.0...1.2.1
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
