## [v2.4.2](https://github.com/voxpupuli/puppet-syntax/tree/v2.4.2) (2019-02-08)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v2.4.1...v2.4.2)

- Search manifests in manifests directory
- Allow .yml as an extension for YAML files.
- Ensure the pkg directory is always excluded
- Check consistency of ENC blobs in eyaml data

## [v2.4.1](https://github.com/voxpupuli/puppet-syntax/tree/v2.4.1) (2017-06-29)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v2.4.0...v2.4.1)

- Fix to ensure namespace scope is inherited.
- Cleanly exits when syntax warnings/errors are found instead of failing.

## [v2.4.0](https://github.com/voxpupuli/puppet-syntax/tree/v2.4.0) (2017-03-14)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v2.3.0...v2.4.0)

- Add check_hiera_keys flag for deep checking of Hiera key name correctness. Thanks @petems.
- Fix Puppet version comparisons for compatibility with Puppet 4.10.
- Fix app_management setting compatibility with Puppet 5.
- Refactor PUPPETVERSION usage to Puppet.version public API.

## [v2.3.0](https://github.com/voxpupuli/puppet-syntax/tree/v2.3.0) (2017-02-01)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v2.2.0...v2.3.0)

- Add app_management flag for Puppet application orchestration support. Thanks @ipcrm.
- Check all *yaml file extensions, including eyaml. thanks @kjetilho, @rjw1.
- Only test ERB syntax in files with an *.erb extension. Thanks @alexiri.
- Extend README to list specific files and checks implemented. Thanks @petems.
- Refactor Rake filelist generation, add tests. Thanks @kjetilho, @rjw1.

## [v2.2.0](https://github.com/voxpupuli/puppet-syntax/tree/v2.2.0) (2016-12-02)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v2.1.1...v2.2.0)

- Replace Puppet.initialize_settings with Puppet::Test::TestHelper. Thanks @domcleal #60
  This clears out caches on every test so increases runtime.

## [v2.1.1](https://github.com/voxpupuli/puppet-syntax/tree/v2.1.1) (2016-10-21)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v2.1.0...v2.1.1)

- Use `$stderr.puts` rather than `warn` and `info` (thanks @mmckinst)
- Allow latest 3.x to validate EPP files (thanks @DavidS)

## [v2.1.0](https://github.com/voxpupuli/puppet-syntax/tree/v2.1.0) (2016-01-18)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v2.0.0...v2.1.0)

- Support Puppet 4. Many thanks to @DavidS
- Support validation of EPP templates. Thanks to @trlinkin
- Test improvements and refactoring, including Travis CI tests against Puppet 4. Thanks to @trlinkin
- Don't error when a tag metaparameter is present. Thank you @dhardy92
- Report the filename of invalid hiera data files. Thanks @danzilio

## [v2.0.0](https://github.com/voxpupuli/puppet-syntax/tree/v2.0.0) (2015-02-26)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v1.4.1...v2.0.0)

- Removed support for Puppet version 2.7.x
- New option, fail_on_deprecation_notices, which defaults to true (compatible
with previous behaviour); thanks @pcfens
- PuppetSyntax::Manifests#check now has two return arguments

## [v1.4.1](https://github.com/voxpupuli/puppet-syntax/tree/v1.4.1) (2015-01-08)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v1.4.0...v1.4.1)

- Support appending to config arrays, thanks @domcleal

## [v1.4.0](https://github.com/voxpupuli/puppet-syntax/tree/v1.4.0) (2014-12-18)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v1.3.0...v1.4.0)

- Rspec 3 is now supported, thanks @tuxmea
- Build error fixed where gem_publisher was used prematurely
- Lazy load Puppet only when it's required, thanks @logicminds

## [v1.3.0](https://github.com/voxpupuli/puppet-syntax/tree/v1.3.0) (2014-08-07)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v1.2.3...v1.3.0)

- Add the ability to pass hieradata_paths array of globs to check
- Check hieradata in modules ('**/data/**/*.yaml') by default

## [v1.2.3](https://github.com/voxpupuli/puppet-syntax/tree/v1.2.3) (2014-08-06)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v1.2.2...v1.2.3)

- Fix puppetlabs_spec_helper warning on Ruby 1.8

## [v1.2.2](https://github.com/voxpupuli/puppet-syntax/tree/v1.2.2) (2014-07-31)

[Full Changelog](https://github.com/voxpupuli/puppet-syntax/compare/v1.2.0...v1.2.2)

- Check and document conflicts with puppetlabs_spec_helper <= 0.7.0

## v1.2.1 (2014-07-23)

- Remove dependency on Puppet from Gemspec (for Puppet Entreprise users).

## v1.2.0 (2014-03-28)

- Optional support for Puppet's future parser.

## v1.1.1 (2014-03-17)

- Ignore exit(1) from Puppet 3.4
- Don't use hardcoded version of parser face.

## v1.1.0 (2013-09-06)

- Syntax checks for Hiera YAML files.
- Improved documentation.

## v1.0.0 (2013-07-04)

- Refactor code to make it easier to test.
- Implement spec tests for syntax checks.
- Pending spec tests for FileList matching.
- Matrix tests for other Ruby/Puppet versions.
- Improve usage example in README.

## v0.0.4 (2013-06-14)

- Fix `$confdir` error for Puppet 3.x

## v0.0.3 (2013-06-11)

- List rake as a dependency.
- Output names of tasks to STDERR.
- Match template paths correctly.
- Add pending spec tests, not yet working.

## v0.0.2 (2013-06-10)

- Fix namespacing of rake tasks.

## v0.0.1 (2013-06-10)

- Initial release
