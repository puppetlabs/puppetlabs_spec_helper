<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v7.2.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.2.0) - 2024-04-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v7.1.0...v7.2.0)

### Added

- (CAT-273) Remove plan exclusion from rake tasks [#447](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/447) ([LukasAud](https://github.com/LukasAud))

### Fixed

- puppet-syntax: Ensure we are using 4.1.1 or newer [#445](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/445) ([bastelfreak](https://github.com/bastelfreak))

## [v7.1.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.1.0) - 2024-03-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v7.0.5...v7.1.0)

### Added

- puppet-syntax: Validate Hiera keys [#444](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/444) ([bastelfreak](https://github.com/bastelfreak))
- puppet-syntax: Validate hiera keys [#441](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/441) ([bastelfreak](https://github.com/bastelfreak))

## [v7.0.5](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.0.5) - 2024-02-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v7.0.4...v7.0.5)

### Fixed

- (bug) - check for empty fixtures array, as well as nil [#435](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/435) ([jordanbreen28](https://github.com/jordanbreen28))

## [v7.0.4](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.0.4) - 2024-02-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v7.0.3...v7.0.4)

### Fixed

- puppet-syntax: Require 4.x [#433](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/433) ([bastelfreak](https://github.com/bastelfreak))
- (GH-397) - Honour default symlink when additional symlinks delcared [#431](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/431) ([jordanbreen28](https://github.com/jordanbreen28))
- (GH-422) - Allow `ref` to be optional in fixtures [#430](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/430) ([jordanbreen28](https://github.com/jordanbreen28))

## [v7.0.3](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.0.3) - 2024-01-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v7.0.2...v7.0.3)

### Fixed

- (CAT-1688) Upgrade Rubocop to `~> 1.50.0` [#426](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/426) ([LukasAud](https://github.com/LukasAud))
- (maint) - Make codecov gem support optional - changes to spec:simplecov rake task [#424](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/424) ([jordanbreen28](https://github.com/jordanbreen28))

## [v7.0.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.0.2) - 2023-12-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v7.0.1...v7.0.2)

### Fixed

- Skip non-existing paths in $MODULEPATH silently [#419](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/419) ([kjetilho](https://github.com/kjetilho))

## [v7.0.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.0.1) - 2023-11-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v7.0.0...v7.0.1)

### Fixed

- (CAT-1603) - Revert back to puppet-lint and rspec-puppet [#417](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/417) ([jordanbreen28](https://github.com/jordanbreen28))

## [v7.0.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v7.0.0) - 2023-10-18

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v6.0.3...v7.0.0)

### Changed
- (CAT-1222) - Require puppetlabs-rspec-puppet over rspec-puppet [#415](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/415) ([jordanbreen28](https://github.com/jordanbreen28))
- (CAT-1256)- Require puppetlabs-puppet-lint over puppet-lint [#411](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/411) ([GSPatton](https://github.com/GSPatton))

## [v6.0.3](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v6.0.3) - 2023-10-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v6.0.2...v6.0.3)

### Fixed

- (bug) - remove obselete manfiest dir config setting & require rspec-puppet 4.x [#412](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/412) ([jordanbreen28](https://github.com/jordanbreen28))

## [v6.0.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v6.0.2) - 2023-09-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v6.0.1...v6.0.2)

### Fixed

- (CAT-1430) - Require puppet-lint ~> 4.0 [#409](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/409) ([jordanbreen28](https://github.com/jordanbreen28))

## [v6.0.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v6.0.1) - 2023-04-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v6.0.0...v6.0.1)

### Fixed

- (MAINT) Bump lint and rspec-puppet dependencies [#395](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/395) ([chelnak](https://github.com/chelnak))

## [v6.0.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v6.0.0) - 2023-04-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v6.0.0.rc.1...v6.0.0)

### Added

- Use rspec-puppet settings to configure Puppet [#389](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/389) ([ekohl](https://github.com/ekohl))

## [v6.0.0.rc.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v6.0.0.rc.1) - 2023-04-19

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v5.0.3...v6.0.0.rc.1)

### Changed
- (CONT-807) Add Ruby 3.2 support [#390](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/390) ([GSPatton](https://github.com/GSPatton))

### Added

- (CONT-807) Ruby 3 / Puppet 8 Additions [#393](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/393) ([chelnak](https://github.com/chelnak))

## [v5.0.3](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v5.0.3) - 2023-01-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v5.0.2...v5.0.3)

## [v5.0.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v5.0.2) - 2023-01-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v5.0.1...v5.0.2)

### Fixed

- (CONT-515) Fix uninitialized constant error [#379](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/379) ([chelnak](https://github.com/chelnak))
- puppet-lint: Allow 3.x [#378](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/378) ([bastelfreak](https://github.com/bastelfreak))
- pathspec: Allow 1.x [#377](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/377) ([bastelfreak](https://github.com/bastelfreak))

## [v5.0.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v5.0.1) - 2023-01-23

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v5.0.0...v5.0.1)

### Fixed

- (GH-372) Reset min Ruby requirement [#373](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/373) ([chelnak](https://github.com/chelnak))

## [v5.0.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v5.0.0) - 2023-01-23

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v4.0.1...v5.0.0)

### Changed
- (CONT-237) Deprecation and legacy version support removal [#364](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/364) ([chelnak](https://github.com/chelnak))
- (CONT-237) Bump minimum Ruby version requirement [#358](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/358) ([chelnak](https://github.com/chelnak))
- Drop outdated future parser support [#348](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/348) ([binford2k](https://github.com/binford2k))

### Added

- Add rspec-github integration [#353](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/353) ([ekohl](https://github.com/ekohl))
- Run the `strings:validate:reference` task during `validate` [#352](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/352) ([smortex](https://github.com/smortex))
- Configure puppet-lint to fail on warnings again [#347](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/347) ([ekohl](https://github.com/ekohl))

### Fixed

- (CONT-237) Rubocop updates [#360](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/360) ([chelnak](https://github.com/chelnak))
- Fix check:git_ignore rake task for git >= 2.32.0 [#346](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/346) ([ekohl](https://github.com/ekohl))

## [v4.0.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v4.0.1) - 2021-08-23

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v4.0.0...v4.0.1)

### Fixed

- (PDK-1717) Add guard clause to module path dir enum loop [#342](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/342) ([sanfrancrisko](https://github.com/sanfrancrisko))

## [v4.0.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v4.0.0) - 2021-07-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v3.0.0...v4.0.0)

### Added

- Use Rubocop's Github Actions formatter if possible [#340](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/340) ([ekohl](https://github.com/ekohl))
- Remove beaker integration [#338](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/338) ([ekohl](https://github.com/ekohl))

## [v3.0.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v3.0.0) - 2021-02-10

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.16.0...v3.0.0)

### Added

- Restructure PuppetLint rake tasks so they can be configurable [#330](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/330) ([nmaludy](https://github.com/nmaludy))

## [v2.16.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.16.0) - 2021-01-18

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.15.0...v2.16.0)

### Added

- Add a check task [#327](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/327) ([ekohl](https://github.com/ekohl))
- Update fixtures from forge when the module version doesn't match; fix git < 2.7 compatibility [#269](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/269) ([nabertrand](https://github.com/nabertrand))
- Add all spec/lib directories from fixtures to LOAD_PATH [#233](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/233) ([nabertrand](https://github.com/nabertrand))

## [v2.15.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.15.0) - 2020-06-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.14.1...v2.15.0)

### Added

- Add Ruby 2.6/Puppet6 to CI matrix [#311](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/311) ([bastelfreak](https://github.com/bastelfreak))
- (GH-297) Don't allow git refs with forward slashes [#299](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/299) ([glennsarti](https://github.com/glennsarti))
- Support git fixture branches containing slashes [#297](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/297) ([trevor-vaughan](https://github.com/trevor-vaughan))
- Accept `:tag` for consistency with r10k [#296](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/296) ([binford2k](https://github.com/binford2k))
- Ignore plans folder and any subfolder [#294](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/294) ([cyberious](https://github.com/cyberious))
- Download forge modules in parallel [#284](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/284) ([logicminds](https://github.com/logicminds))
- (maint) migrate the changelog task from pdk-templates [#278](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/278) ([DavidS](https://github.com/DavidS))

### Fixed

- (MAINT) Fix initialize of Gettext call [#292](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/292) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))

## [v2.14.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.14.1) - 2019-03-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.14.0...v2.14.1)

### Fixed

- Revert "(feat) dont load the beaker if litmus is there" [#286](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/286) ([pmcmaw](https://github.com/pmcmaw))

## [v2.14.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.14.0) - 2019-03-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.13.1...v2.14.0)

### Added

- (feat) dont load the beaker if litmus is there [#281](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/281) ([tphoney](https://github.com/tphoney))
- (maint) load rake tasks from optional libraries [#279](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/279) ([DavidS](https://github.com/DavidS))
- Document how to set default values for fixture loading [#277](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/277) ([Felixoid](https://github.com/Felixoid))

### Fixed

- Remove `--color` from everywhere, use RSpec default detection instead [#280](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/280) ([DavidS](https://github.com/DavidS))

## [v2.13.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.13.1) - 2019-01-15

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.13.0...v2.13.1)

### Fixed

- Revert "(MODULES-8242) - Fix CI_SPEC_OPTIONS failing" [#275](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/275) ([rodjek](https://github.com/rodjek))

## [v2.13.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.13.0) - 2019-01-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.12.0...v2.13.0)

### Added

- (PDK-1199) Honour .{pdk,git}ignore in check:symlinks rake task [#267](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/267) ([rodjek](https://github.com/rodjek))
- (PDK-1137) Determine module name from metadata when possible [#265](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/265) ([rodjek](https://github.com/rodjek))

### Fixed

- (MODULES-8242) - Fix CI_SPEC_OPTIONS failing [#268](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/268) ([stamm](https://github.com/stamm))
- (PDK-997) Remove Dir.chdir call from check:test_file task [#266](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/266) ([rodjek](https://github.com/rodjek))

## [v2.12.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.12.0) - 2018-11-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.11.0...v2.12.0)

### Added

- Added tasks to rspec pattern. [#261](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/261) ([dylanratcliffe](https://github.com/dylanratcliffe))
- (PDK-1100) Use PDK to build module packages [#260](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/260) ([rodjek](https://github.com/rodjek))

### Fixed

- (bugfix) ignore bundle directory, for symlinks [#263](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/263) ([tphoney](https://github.com/tphoney))
- (MODULES-7273) - Raise error when fixture ref invalid [#262](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/262) ([eimlav](https://github.com/eimlav))

## [v2.11.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.11.0) - 2018-09-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.10.0...v2.11.0)

### Added

- (MODULES-7856) Allow optional repositories based on puppet version [#258](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/258) ([joshcooper](https://github.com/joshcooper))

### Fixed

- Fix example conversion from mocha to rspec mocks. [#257](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/257) ([vStone](https://github.com/vStone))

## [v2.10.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.10.0) - 2018-08-30

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.9.1...v2.10.0)

### Added

- (feat) add puppet lint fix task [#255](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/255) ([tphoney](https://github.com/tphoney))
- add support to override the allowed test tiers [#253](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/253) ([b4ldr](https://github.com/b4ldr))

## [v2.9.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.9.1) - 2018-06-20

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.9.0...v2.9.1)

### Fixed

- (PDK-1031) Remove thread-unsafe Dir.chdir usage [#249](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/249) ([rodjek](https://github.com/rodjek))
- (PDK-1033) Use `--unshallow` when fetching a ref [#247](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/247) ([DavidS](https://github.com/DavidS))

## [v2.9.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.9.0) - 2018-06-18

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.8.0...v2.9.0)

### Added

- (maint) adding ruby code coverage setup and rake task [#245](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/245) ([tphoney](https://github.com/tphoney))

## [v2.8.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.8.0) - 2018-05-31

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.7.0...v2.8.0)

### Added

- minor edits to mock_with section [#243](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/243) ([jbondpdx](https://github.com/jbondpdx))
- (PDK-636) Groundwork to allow PDK to persist downloaded fixtures [#242](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/242) ([rodjek](https://github.com/rodjek))
- (PDK-636) Always remove symlink fixtures. Only remove downloaded fixtures if tests pass. [#241](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/241) ([rodjek](https://github.com/rodjek))

## [v2.7.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.7.0) - 2018-04-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.6.2...v2.7.0)

### Added

- (PDK-916) Default to mocha if mock_framework isn't set [#239](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/239) ([MikaelSmith](https://github.com/MikaelSmith))
- Break out beaker and fixture tasks into separate files [#238](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/238) ([DavidS](https://github.com/DavidS))
- (BOLT-397) add spec/plans/**/*_spec.rb to spec discovery pattern [#235](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/235) ([adreyer](https://github.com/adreyer))

### Fixed

- Allow module_spec_helper to work with mocha 1.5.0 and rspec mocking [#237](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/237) ([DavidS](https://github.com/DavidS))
- (FM-6813) fix parsing for test tiers [#231](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/231) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))

## [v2.6.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.6.2) - 2018-02-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.6.1...v2.6.2)

### Added

- (MODULES-6606) change to initialize_config [#225](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/225) ([eputnam](https://github.com/eputnam))

## [v2.6.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.6.1) - 2017-12-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.6.0...v2.6.1)

### Added

- Fix fixtures defaults and add tests [#223](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/223) ([hunner](https://github.com/hunner))

## [v2.6.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.6.0) - 2017-12-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.5.1...v2.6.0)

## [v2.5.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.5.1) - 2017-11-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.5.0...v2.5.1)

### Fixed

- bugfix - parallel_spec fails with no files to test [#216](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/216) ([tphoney](https://github.com/tphoney))

## [v2.5.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.5.0) - 2017-11-15

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.4.0...v2.5.0)

### Added

- (PDK-429) add tests argument to rake spec [#209](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/209) ([8675309](https://github.com/8675309))

### Fixed

- (WIN-6) trim whitespace from test_tiers before parsing [#214](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/214) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))

## [v2.4.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.4.0) - 2017-10-17

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.3.2...v2.4.0)

### Added

- (MODULES-5503) Add support for repository targets [#210](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/210) ([trevor-vaughan](https://github.com/trevor-vaughan))
- Mercurial branch support [#208](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/208) ([pegasd](https://github.com/pegasd))

### Fixed

- (WIN-6) Add test_tiers env var parsing to support test tiering. [#212](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/212) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- Fix release_checks without parallel_tests [#211](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/211) ([sean797](https://github.com/sean797))
- Fix 'abort: please specify just one revision' mercurial error [#206](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/206) ([pegasd](https://github.com/pegasd))

## [v2.3.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.3.2) - 2017-08-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.3.1...v2.3.2)

### Added

- (PDK-409) Make directory junction targets relative to the junction [#203](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/203) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-381) Ensure spec fixtures are cleaned up, even if the test fails [#204](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/204) ([rodjek](https://github.com/rodjek))

## [v2.3.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.3.1) - 2017-08-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.3.0...v2.3.1)

### Fixed

- (PDK-373) Add rake task to list spec tests [#201](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/201) ([james-stocks](https://github.com/james-stocks))

## [v2.3.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.3.0) - 2017-07-20

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.2.0...v2.3.0)

### Added

- Support CI options for parallel_spec [#199](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/199) ([austb](https://github.com/austb))

## [v2.2.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.2.0) - 2017-06-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.5...v2.2.0)

### Added

- Change default logger output to STDERR. [#197](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/197) ([scotje](https://github.com/scotje))
- Update default fixture path calculation to be Windows safe. [#196](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/196) ([scotje](https://github.com/scotje))
- Adding a parent rake task for i18n of a module [#194](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/194) ([HelenCampbell](https://github.com/HelenCampbell))

## [v2.1.5](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.1.5) - 2017-06-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.4...v2.1.5)

## [v2.1.4](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.1.4) - 2017-06-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.3...v2.1.4)

### Added

- (SDK-168) Replace check:symlinks with platform independent alternative [#193](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/193) ([rodjek](https://github.com/rodjek))
- (SDK-268) Create directory junctions instead of symlinks on windows [#192](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/192) ([rodjek](https://github.com/rodjek))

## [v2.1.3](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.1.3) - 2017-05-31

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.2...v2.1.3)

### Added

- (FM-6170) Addition of branch check for build number creation [#190](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/190) ([HelenCampbell](https://github.com/HelenCampbell))

### Fixed

- (maint) Properly escape paths [#191](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/191) ([samuelson](https://github.com/samuelson))

## [v2.1.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.1.2) - 2017-04-17

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.1...v2.1.2)

## [v2.1.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.1.1) - 2017-03-29

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.1.0...v2.1.1)

### Added

- Add dependency on parallel_tests [#186](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/186) ([ekohl](https://github.com/ekohl))

## [v2.1.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.1.0) - 2017-03-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.0.2...v2.1.0)

### Added

- (MODULES-4471) Add CI_SPEC_OPTIONS environment variable to modify rspec [#182](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/182) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (maint) fix load order for gettext-setup tasks [#183](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/183) ([eputnam](https://github.com/eputnam))

## [v2.0.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.0.2) - 2017-02-23

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.0.1...v2.0.2)

### Fixed

- (maint) fix gettext rake tasks [#180](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/180) ([eputnam](https://github.com/eputnam))

## [v2.0.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.0.1) - 2017-02-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v2.0.0...v2.0.1)

## [v2.0.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v2.0.0) - 2017-02-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v1.2.2...v2.0.0)

### Added

- (MODULES-4394) Make the module_working_dir configurable [#175](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/175) ([glennsarti](https://github.com/glennsarti))
- Add type_aliases directory [#174](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/174) ([domcleal](https://github.com/domcleal))
- (MODULES-3212) change to parallel_spec [#173](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/173) ([eputnam](https://github.com/eputnam))
- (FM-5989) add i18n tools [#172](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/172) ([eputnam](https://github.com/eputnam))
- (maint) Module install - ensure paths use / [#171](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/171) ([ferventcoder](https://github.com/ferventcoder))

## [v1.2.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v1.2.2) - 2016-08-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/v1.2.1...v1.2.2)

### Added

- Only set strict_variables setting when required [#168](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/168) ([domcleal](https://github.com/domcleal))

## [v1.2.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/v1.2.1) - 2016-08-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.2.0...v1.2.1)

## [1.2.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/1.2.0) - 2016-08-23

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.1.1...1.2.0)

### Changed
- Deprecate PuppetInternals.scope [#108](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/108) ([DavidS](https://github.com/DavidS))

### Added

- Update puppet-lint and puppet-syntax default ignore paths [#165](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/165) ([DavidS](https://github.com/DavidS))

## [1.1.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/1.1.1) - 2016-03-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.1.0...1.1.1)

### Fixed

- Re-add the missing metadata task with a depreciation warning [#131](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/131) ([DavidS](https://github.com/DavidS))

## [1.1.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/1.1.0) - 2016-02-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.0.1...1.1.0)

## [1.0.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/1.0.1) - 2015-11-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/1.0.0...1.0.1)

### Fixed

- Should use Errno, not Error [#119](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/119) ([kristvanbesien](https://github.com/kristvanbesien))

## [1.0.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/1.0.0) - 2015-11-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.3...1.0.0)

### Fixed

- Add more info to the `abort()` on malformed YAML [#111](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/111) ([daenney](https://github.com/daenney))
- (MODULES-2090) fixes bug in rake_tasks config [#106](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/106) ([bmjen](https://github.com/bmjen))

## [0.10.3](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.10.3) - 2015-05-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.2...0.10.3)

### Added

- Update Lint to default to Puppet Approved criteria [#80](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/80) ([cyberious](https://github.com/cyberious))

### Fixed

- Don't set settings removed in puppet4 if testing against puppet4 [#102](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/102) ([underscorgan](https://github.com/underscorgan))

## [0.10.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.10.2) - 2015-04-14

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.1...0.10.2)

### Added

- Updates for puppet 4 [#100](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/100) ([hunner](https://github.com/hunner))

## [0.10.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.10.1) - 2015-03-17

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.10.0...0.10.1)

### Added

- Only use --depth 1 if ref is not used [#96](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/96) ([treydock](https://github.com/treydock))

## [0.10.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.10.0) - 2015-03-16

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.9.1...0.10.0)

### Added

- Use faster shallow git clone [#94](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/94) ([sbadia](https://github.com/sbadia))
- Exclude vendor/ files [#86](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/86) ([domcleal](https://github.com/domcleal))

## [0.9.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.9.1) - 2015-02-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.9.0...0.9.1)

## [0.9.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.9.0) - 2015-02-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.8.2...0.9.0)

### Added

- Enable future parser testing [#91](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/91) ([cmurphy](https://github.com/cmurphy))
- Stub root? method so spec tests can test execs [#88](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/88) ([cmurphy](https://github.com/cmurphy))
- (MODULES-1576) Use Puppet FileSystem abstraction for symlinks to support Windows [#84](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/84) ([Iristyle](https://github.com/Iristyle))
- Run metadata-json-lint under validate rake task [#82](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/82) ([domcleal](https://github.com/domcleal))

### Fixed

- fix load issue with puppet filesystem and windows symlinks [#87](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/87) ([logicminds](https://github.com/logicminds))
- (MODULES-1576) Fix symlink support for older Puppet versions [#85](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/85) ([Iristyle](https://github.com/Iristyle))

## [0.8.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.8.2) - 2014-10-01

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.8.0...0.8.2)

### Fixed

- (MODULES-1353) Correct the puppet-lint tasks path [#78](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/78) ([3flex](https://github.com/3flex))

## [0.8.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.8.0) - 2014-08-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.7.0...0.8.0)

### Added

- Allow relative paths and params [#76](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/76) ([hunner](https://github.com/hunner))
- Replace syntax checks with puppet-syntax [#73](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/73) ([dcarley](https://github.com/dcarley))

### Fixed

- Fix rspec 3.0 error when loading spec_helper [#74](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/74) ([jeffmccune](https://github.com/jeffmccune))

## [0.7.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.7.0) - 2014-07-17

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.6.0...0.7.0)

### Added

- (MODULES-1214) Allow .fixtures.yml to specify a git branch [#71](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/71) ([treydock](https://github.com/treydock))
- MODULES-1202 - add module_spec_helper support for 3.6 config items [#70](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/70) ([jantman](https://github.com/jantman))
- (MODULES-1190) respect puppet-lint ignore paths in Rakefile [#69](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/69) ([mmickan](https://github.com/mmickan))

## [0.6.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.6.0) - 2014-07-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.5.2...0.6.0)

### Added

- (MODULES-1189) force module install in spec_prep [#67](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/67) ([3flex](https://github.com/3flex))
- Add :validate as a rake task [#66](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/66) ([cmurphy](https://github.com/cmurphy))
- Add future parser and strict variable test support [#65](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/65) ([hunner](https://github.com/hunner))

### Fixed

- avoid name clash with Object.clone method [#64](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/64) ([ehaselwanter](https://github.com/ehaselwanter))

## [0.5.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.5.2) - 2014-06-19

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.5.1...0.5.2)

## [0.5.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.5.1) - 2014-06-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.5.0...0.5.1)

### Added

- Add mocha mocking back [#60](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/60) ([hunner](https://github.com/hunner))

## [0.5.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.5.0) - 2014-06-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.4.2...0.5.0)

### Added

- Remove mocha dependency and rspec pinning [#59](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/59) ([hunner](https://github.com/hunner))

## [0.4.2](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.4.2) - 2014-06-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.4.1...0.4.2)

### Added

- Only clean up site.pp fixture if zero length [#50](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/50) ([wcooley](https://github.com/wcooley))
- Add beaker and beaker_nodes tasks [#47](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/47) ([blkperl](https://github.com/blkperl))
- Add support for "forge_modules" in fixtures. [#46](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/46) ([wcooley](https://github.com/wcooley))
- spec_clean does not fail if it has already been run [#44](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/44) ([hawknewton](https://github.com/hawknewton))
- Changed to forced symlinks in the event that symlink is old a spec_prep ... [#43](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/43) ([tehmaspc](https://github.com/tehmaspc))
- support more than just git in fixtures [#41](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/41) ([igalic](https://github.com/igalic))
- be more ignorant [#40](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/40) ([igalic](https://github.com/igalic))
- Remove gemspec - it's superseded by our Rakefile [#39](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/39) ([igalic](https://github.com/igalic))
- Do not lint fixtures directory. [#38](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/38) ([nanliu](https://github.com/nanliu))
- Add syntax checking task [#36](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/36) ([dalen](https://github.com/dalen))
- (#21602) Updated rake_tasks.rb to include 'integration' folder when running spec tests. [#35](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/35) ([fatmcgav](https://github.com/fatmcgav))

### Fixed

- Fix for empty repository list in .fixtures.yml file [#42](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/42) ([tehmaspc](https://github.com/tehmaspc))
- Fix issue with aborted rake task when packaging gem. [#34](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/34) ([AlexCline](https://github.com/AlexCline))
- Fix Puppet Labs Issue Tracker URL [#33](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/33) ([DavidS](https://github.com/DavidS))
- Don't reset when target is missing [#30](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/30) ([hunner](https://github.com/hunner))

## [0.4.1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.4.1) - 2013-02-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.4.0...0.4.1)

## [0.4.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.4.0) - 2012-12-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.4.0-rc1...0.4.0)

## [0.4.0-rc1](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.4.0-rc1) - 2012-12-14

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.3.0...0.4.0-rc1)

### Fixed

- Rake should fail if git can't clone repository [#28](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/28) ([hunner](https://github.com/hunner))
- Fix Mocha deprecations [#26](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/26) ([mitchellh](https://github.com/mitchellh))
- Only remove the site.pp if it is empty [#24](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/24) ([hunner](https://github.com/hunner))

## [0.3.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.3.0) - 2012-08-14

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.2.0...0.3.0)

### Fixed

- Revert "Merge pull request #15 from ghoneycutt/add_hiera_support" [#16](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/16) ([branan](https://github.com/branan))

## [0.2.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.2.0) - 2012-07-05

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/0.1.0...0.2.0)

### Fixed

- fix broken coverage rake task. [#10](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/10) ([mafalb](https://github.com/mafalb))
- Create missing spec/fixtures/manifests [#9](https://github.com/puppetlabs/puppetlabs_spec_helper/pull/9) ([mafalb](https://github.com/mafalb))

## [0.1.0](https://github.com/puppetlabs/puppetlabs_spec_helper/tree/0.1.0) - 2012-06-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs_spec_helper/compare/5d2e3a6da74c351e3f0619acc0e1684089ad01a2...0.1.0)
