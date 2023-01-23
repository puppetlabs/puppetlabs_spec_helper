## [v1.8.1](https://github.com/puppetlabs/puppet-resource_api/tree/v1.8.1) (2019-03-13)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.8.0...v1.8.1)

**Fixed bugs:**

- \(maint\) Fixes sensitive transport values where absent keys are wrapped [\#161](https://github.com/puppetlabs/puppet-resource_api/pull/161) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- 1.6.x mergeup [\#162](https://github.com/puppetlabs/puppet-resource_api/pull/162) ([DavidS](https://github.com/DavidS))
- \(FM-7829\) Update README with transports examples [\#160](https://github.com/puppetlabs/puppet-resource_api/pull/160) ([willmeek](https://github.com/willmeek))
- \(maint\) update release docs [\#159](https://github.com/puppetlabs/puppet-resource_api/pull/159) ([DavidS](https://github.com/DavidS))
- Improve travis cells and testing [\#145](https://github.com/puppetlabs/puppet-resource_api/pull/145) ([DavidS](https://github.com/DavidS))

## [v1.8.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.8.0) (2019-02-26)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.7.0...v1.8.0)

**Implemented enhancements:**

- \(FM-7695\) Transports - the remote content framework [\#157](https://github.com/puppetlabs/puppet-resource_api/pull/157) ([DavidS](https://github.com/DavidS))
- \(FM-7698\) implement `sensitive:true` handling [\#156](https://github.com/puppetlabs/puppet-resource_api/pull/156) ([da-ar](https://github.com/da-ar))
- \(PDK-1271\) Allow a transport to be wrapped and used like a device [\#155](https://github.com/puppetlabs/puppet-resource_api/pull/155) ([da-ar](https://github.com/da-ar))
- \(FM-7701\) Support device providers when using Transport Wrapper [\#154](https://github.com/puppetlabs/puppet-resource_api/pull/154) ([da-ar](https://github.com/da-ar))
- \(FM-7726\) implement `context.transport` to provide access [\#152](https://github.com/puppetlabs/puppet-resource_api/pull/152) ([DavidS](https://github.com/DavidS))
- \(FM-7674\) Allow wrapping a Transport in a legacy Device [\#149](https://github.com/puppetlabs/puppet-resource_api/pull/149) ([da-ar](https://github.com/da-ar))
- \(FM-7600\) Add Transport.connect method [\#148](https://github.com/puppetlabs/puppet-resource_api/pull/148) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(FM-7690\) Fix transports cache to be environment aware [\#151](https://github.com/puppetlabs/puppet-resource_api/pull/151) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- Release prep for v1.8.0 [\#158](https://github.com/puppetlabs/puppet-resource_api/pull/158) ([DavidS](https://github.com/DavidS))
- \(FM-7726\) cleanups for the transport  [\#153](https://github.com/puppetlabs/puppet-resource_api/pull/153) ([DavidS](https://github.com/DavidS))
- \(FM-7691,FM-7696\) refactoring definition handling in contexts [\#150](https://github.com/puppetlabs/puppet-resource_api/pull/150) ([DavidS](https://github.com/DavidS))

## [v1.7.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.7.0) (2019-01-07)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.6.3...v1.7.0)

**Implemented enhancements:**

- \(maint\) Validate Type Schema [\#142](https://github.com/puppetlabs/puppet-resource_api/pull/142) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- \(maint\) Bundler 2.0 dropped support for Ruby versions \< 2.2 [\#147](https://github.com/puppetlabs/puppet-resource_api/pull/147) ([da-ar](https://github.com/da-ar))
-  \(FM-7597\) RSAPI Transport register function [\#146](https://github.com/puppetlabs/puppet-resource_api/pull/146) ([da-ar](https://github.com/da-ar))
- \(packaging\) Update version to 1.7.0 [\#144](https://github.com/puppetlabs/puppet-resource_api/pull/144) ([branan](https://github.com/branan))

## [v1.6.3](https://github.com/puppetlabs/puppet-resource_api/tree/v1.6.3) (2018-12-11)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.6.2...v1.6.3)

**Closed issues:**

- Trying to understand stubbing in the examples [\#136](https://github.com/puppetlabs/puppet-resource_api/issues/136)

**Merged pull requests:**

- \(packaging\) Update version to 1.6.3 [\#143](https://github.com/puppetlabs/puppet-resource_api/pull/143) ([branan](https://github.com/branan))
- Move parameter and property logic to separate classes [\#140](https://github.com/puppetlabs/puppet-resource_api/pull/140) ([bpietraga](https://github.com/bpietraga))
- \(maint\) Predeclare Puppet module before ResourceApi [\#139](https://github.com/puppetlabs/puppet-resource_api/pull/139) ([caseywilliams](https://github.com/caseywilliams))
- \(maint\) minor fix to make data\_type\_handling change work [\#138](https://github.com/puppetlabs/puppet-resource_api/pull/138) ([DavidS](https://github.com/DavidS))
- \(maint\) extract data type handling code [\#137](https://github.com/puppetlabs/puppet-resource_api/pull/137) ([bpietraga](https://github.com/bpietraga))
- Release prep for v1.6.2 [\#135](https://github.com/puppetlabs/puppet-resource_api/pull/135) ([DavidS](https://github.com/DavidS))

## [v1.6.2](https://github.com/puppetlabs/puppet-resource_api/tree/v1.6.2) (2018-10-25)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.6.1...v1.6.2)

**Fixed bugs:**

- \(PDK-1209\) Fix the other call-sites of const\_defined? and const\_get [\#134](https://github.com/puppetlabs/puppet-resource_api/pull/134) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release prep for v1.6.1 [\#133](https://github.com/puppetlabs/puppet-resource_api/pull/133) ([DavidS](https://github.com/DavidS))

## [v1.6.1](https://github.com/puppetlabs/puppet-resource_api/tree/v1.6.1) (2018-10-25)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.6.0...v1.6.1)

**Fixed bugs:**

- \(PDK-1209\) setting inherited const\_defined lookup to false [\#132](https://github.com/puppetlabs/puppet-resource_api/pull/132) ([Thomas-Franklin](https://github.com/Thomas-Franklin))

**Merged pull requests:**

- Updated announcement instructions [\#131](https://github.com/puppetlabs/puppet-resource_api/pull/131) ([davinhanlon](https://github.com/davinhanlon))
- Minor spelling fix [\#130](https://github.com/puppetlabs/puppet-resource_api/pull/130) ([AlmogCohen](https://github.com/AlmogCohen))
- Add internal announcement list to template [\#129](https://github.com/puppetlabs/puppet-resource_api/pull/129) ([DavidS](https://github.com/DavidS))
- Adjust announcement template to reality [\#128](https://github.com/puppetlabs/puppet-resource_api/pull/128) ([DavidS](https://github.com/DavidS))
- Release prep for v1.6.0 [\#127](https://github.com/puppetlabs/puppet-resource_api/pull/127) ([da-ar](https://github.com/da-ar))

## [v1.6.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.6.0) (2018-09-25)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.5.0...v1.6.0)

**Implemented enhancements:**

- \(PDK-1185\) Implement allowances for device-specific providers [\#126](https://github.com/puppetlabs/puppet-resource_api/pull/126) ([DavidS](https://github.com/DavidS))
- \(PDK-1143\) Allow SimpleProvider to handle multiple namevars [\#125](https://github.com/puppetlabs/puppet-resource_api/pull/125) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- Update README walkthrough [\#122](https://github.com/puppetlabs/puppet-resource_api/pull/122) ([AlmogCohen](https://github.com/AlmogCohen))

**Merged pull requests:**

- Update README [\#124](https://github.com/puppetlabs/puppet-resource_api/pull/124) ([clairecadman](https://github.com/clairecadman))
- Update README [\#123](https://github.com/puppetlabs/puppet-resource_api/pull/123) ([DavidS](https://github.com/DavidS))
- \(maint\) Add Travis job for Puppet 6.0.x branch [\#120](https://github.com/puppetlabs/puppet-resource_api/pull/120) ([da-ar](https://github.com/da-ar))
- Release prep for v1.5.0 [\#119](https://github.com/puppetlabs/puppet-resource_api/pull/119) ([DavidS](https://github.com/DavidS))

## [v1.5.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.5.0) (2018-09-12)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.4.2...v1.5.0)

**Implemented enhancements:**

- \(PDK-1150\) Allow providers to override :title when retrieving resources [\#115](https://github.com/puppetlabs/puppet-resource_api/pull/115) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(maint\) create a new default value instance on every access [\#118](https://github.com/puppetlabs/puppet-resource_api/pull/118) ([DavidS](https://github.com/DavidS))
- \(PDK-1091\) Fix Sensitive value handling [\#117](https://github.com/puppetlabs/puppet-resource_api/pull/117) ([DavidS](https://github.com/DavidS))
- \(MODULES-7679\) correctly handle simple\_get\_filter providers [\#113](https://github.com/puppetlabs/puppet-resource_api/pull/113) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- Release prep for v1.4.2 [\#112](https://github.com/puppetlabs/puppet-resource_api/pull/112) ([DavidS](https://github.com/DavidS))

## [v1.4.2](https://github.com/puppetlabs/puppet-resource_api/tree/v1.4.2) (2018-08-09)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.4.1...v1.4.2)

**Fixed bugs:**

- Allow an attribute with default boolean value to be set correctly [\#110](https://github.com/puppetlabs/puppet-resource_api/pull/110) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- \(maint\) fix brace alignment; document reference [\#111](https://github.com/puppetlabs/puppet-resource_api/pull/111) ([DavidS](https://github.com/DavidS))
- Release prep for v1.4.1 [\#109](https://github.com/puppetlabs/puppet-resource_api/pull/109) ([DavidS](https://github.com/DavidS))

## [v1.4.1](https://github.com/puppetlabs/puppet-resource_api/tree/v1.4.1) (2018-07-20)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.4.0...v1.4.1)

**Fixed bugs:**

- Fix "undefined method `rs\_value'" error with metaparams [\#108](https://github.com/puppetlabs/puppet-resource_api/pull/108) ([DavidS](https://github.com/DavidS))
- Improve log\_exception output from PuppetContext [\#103](https://github.com/puppetlabs/puppet-resource_api/pull/103) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- Misc fixes: license metadata, announcement template, puppet load fix [\#107](https://github.com/puppetlabs/puppet-resource_api/pull/107) ([DavidS](https://github.com/DavidS))
- Minor changes to README [\#106](https://github.com/puppetlabs/puppet-resource_api/pull/106) ([clairecadman](https://github.com/clairecadman))
- Release prep for v1.4.0 [\#102](https://github.com/puppetlabs/puppet-resource_api/pull/102) ([DavidS](https://github.com/DavidS))

## [v1.4.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.4.0) (2018-06-19)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.3.0...v1.4.0)

**Implemented enhancements:**

- Allow `SimpleDevice` to be initialized with a config hash [\#96](https://github.com/puppetlabs/puppet-resource_api/pull/96) ([DavidS](https://github.com/DavidS))
- \(PDK-1007\) implement enough to support purge=\>true  [\#95](https://github.com/puppetlabs/puppet-resource_api/pull/95) ([DavidS](https://github.com/DavidS))
- \(PDK-917\) Validates provider.get values against Type schema [\#88](https://github.com/puppetlabs/puppet-resource_api/pull/88) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(PDK-1004\) log exceptions as they are processed [\#101](https://github.com/puppetlabs/puppet-resource_api/pull/101) ([DavidS](https://github.com/DavidS))
- \(PDK-1000\) do not print nil valued attributes [\#100](https://github.com/puppetlabs/puppet-resource_api/pull/100) ([DavidS](https://github.com/DavidS))
- \(PDK-1007\) Handle setting `ensure` to a Symbol through code [\#94](https://github.com/puppetlabs/puppet-resource_api/pull/94) ([DavidS](https://github.com/DavidS))
- \(PDK-1007\) the namevar is a param [\#91](https://github.com/puppetlabs/puppet-resource_api/pull/91) ([DavidS](https://github.com/DavidS))
- \(PDK-996\) Provide better messaging when type cannot be resolved [\#87](https://github.com/puppetlabs/puppet-resource_api/pull/87) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- Whitespace cleanup with new rubocop version [\#98](https://github.com/puppetlabs/puppet-resource_api/pull/98) ([DavidS](https://github.com/DavidS))
- \(PDK-1007\) add tests for `to\_resource` [\#93](https://github.com/puppetlabs/puppet-resource_api/pull/93) ([DavidS](https://github.com/DavidS))
- Enable randomised rspec testing [\#92](https://github.com/puppetlabs/puppet-resource_api/pull/92) ([da-ar](https://github.com/da-ar))
- appease rubocop 0.57.0 [\#90](https://github.com/puppetlabs/puppet-resource_api/pull/90) ([da-ar](https://github.com/da-ar))
- Improve unit tests of parameter and property results after register\_type [\#89](https://github.com/puppetlabs/puppet-resource_api/pull/89) ([DavidS](https://github.com/DavidS))
- Update release docs and announcement template [\#86](https://github.com/puppetlabs/puppet-resource_api/pull/86) ([DavidS](https://github.com/DavidS))
- Release prep for v1.3.0 [\#85](https://github.com/puppetlabs/puppet-resource_api/pull/85) ([da-ar](https://github.com/da-ar))

## [v1.3.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.3.0) (2018-05-24)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.2.0...v1.3.0)

**Implemented enhancements:**

- Check for more attributes that puppet can't use [\#84](https://github.com/puppetlabs/puppet-resource_api/pull/84) ([DavidS](https://github.com/DavidS))
- \(PDK-531\) Support for composite namevars [\#82](https://github.com/puppetlabs/puppet-resource_api/pull/82) ([da-ar](https://github.com/da-ar))
- \(PDK-889\) Write support for multiple namevars [\#79](https://github.com/puppetlabs/puppet-resource_api/pull/79) ([da-ar](https://github.com/da-ar))
- \(PDK-889\) Read-only support for multiple namevars [\#76](https://github.com/puppetlabs/puppet-resource_api/pull/76) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- Ignore `provider` attribute when calculating target state [\#83](https://github.com/puppetlabs/puppet-resource_api/pull/83) ([DavidS](https://github.com/DavidS))
- Add check to handle absent resources through puppet apply [\#81](https://github.com/puppetlabs/puppet-resource_api/pull/81) ([da-ar](https://github.com/da-ar))
- \(PDK-988\) restrain mungify from non-`puppet resource` workflows [\#80](https://github.com/puppetlabs/puppet-resource_api/pull/80) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Update fixtures module to PDK v1.5 [\#78](https://github.com/puppetlabs/puppet-resource_api/pull/78) ([DavidS](https://github.com/DavidS))
- Some glue fixes: announcement, to\_manifest, to\_hierayaml [\#77](https://github.com/puppetlabs/puppet-resource_api/pull/77) ([DavidS](https://github.com/DavidS))
- Release prep for v1.2.0 [\#75](https://github.com/puppetlabs/puppet-resource_api/pull/75) ([DavidS](https://github.com/DavidS))

## [v1.2.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.2.0) (2018-05-08)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.1.0...v1.2.0)

**Implemented enhancements:**

- \(PDK-924\) Throw when SimpleProvider is used with unensurable type [\#73](https://github.com/puppetlabs/puppet-resource_api/pull/73) ([da-ar](https://github.com/da-ar))
- \(PDK-955\) Provide access to the type definition from the provider [\#72](https://github.com/puppetlabs/puppet-resource_api/pull/72) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(PDK-946\) Passes ensure values to puppet as symbols. [\#74](https://github.com/puppetlabs/puppet-resource_api/pull/74) ([da-ar](https://github.com/da-ar))
- \(PDK-929\) Ignore validation for absent resources [\#69](https://github.com/puppetlabs/puppet-resource_api/pull/69) ([da-ar](https://github.com/da-ar))
- Make ruby files individually loadable without puppet [\#65](https://github.com/puppetlabs/puppet-resource_api/pull/65) ([DavidS](https://github.com/DavidS))
- \(PDK-526\) fix test for git [\#63](https://github.com/puppetlabs/puppet-resource_api/pull/63) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Add pre-commit hook for rubocop [\#70](https://github.com/puppetlabs/puppet-resource_api/pull/70) ([da-ar](https://github.com/da-ar))
- Add a template for release announcements [\#67](https://github.com/puppetlabs/puppet-resource_api/pull/67) ([DavidS](https://github.com/DavidS))
- Cache ~/.rvm for jruby jobs [\#66](https://github.com/puppetlabs/puppet-resource_api/pull/66) ([cotsog](https://github.com/cotsog))
- Release prep for v1.1.0 [\#64](https://github.com/puppetlabs/puppet-resource_api/pull/64) ([DavidS](https://github.com/DavidS))

## [v1.1.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.1.0) (2018-04-12)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.0.3...v1.1.0)

**Implemented enhancements:**

- \(PDK-895\) basic array support [\#59](https://github.com/puppetlabs/puppet-resource_api/pull/59) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- \(PDK-919\) Workaround PUP-2368 "using booleans result in unmanaged pro… [\#62](https://github.com/puppetlabs/puppet-resource_api/pull/62) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- \(PDK-526\) do not rely on git when building the gem on jenkins [\#61](https://github.com/puppetlabs/puppet-resource_api/pull/61) ([DavidS](https://github.com/DavidS))
- \(PDK-896\) Advanced Array tests [\#60](https://github.com/puppetlabs/puppet-resource_api/pull/60) ([DavidS](https://github.com/DavidS))
- Update puppetlabs\_spec\_helper to fixed master version [\#58](https://github.com/puppetlabs/puppet-resource_api/pull/58) ([DavidS](https://github.com/DavidS))
- Release prep for v1.0.3 [\#57](https://github.com/puppetlabs/puppet-resource_api/pull/57) ([DavidS](https://github.com/DavidS))

## [v1.0.3](https://github.com/puppetlabs/puppet-resource_api/tree/v1.0.3) (2018-04-06)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.0.2...v1.0.3)

**Implemented enhancements:**

- \(PDK-887\) Add checks for read\_only values being set or modified [\#54](https://github.com/puppetlabs/puppet-resource_api/pull/54) ([da-ar](https://github.com/da-ar))
- \(PDK-885\) Add support for init\_only attributes [\#52](https://github.com/puppetlabs/puppet-resource_api/pull/52) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(PDK-911\) Fix handling of `ensure` values from symbols to strings [\#55](https://github.com/puppetlabs/puppet-resource_api/pull/55) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Misc fixes [\#56](https://github.com/puppetlabs/puppet-resource_api/pull/56) ([DavidS](https://github.com/DavidS))
- \(PDK-890\) document current constraints on possible data types  [\#53](https://github.com/puppetlabs/puppet-resource_api/pull/53) ([DavidS](https://github.com/DavidS))
- Update release prep notes [\#51](https://github.com/puppetlabs/puppet-resource_api/pull/51) ([DavidS](https://github.com/DavidS))
- Release prep for v1.0.2 [\#50](https://github.com/puppetlabs/puppet-resource_api/pull/50) ([DavidS](https://github.com/DavidS))

## [v1.0.2](https://github.com/puppetlabs/puppet-resource_api/tree/v1.0.2) (2018-03-26)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.0.1...v1.0.2)

**Implemented enhancements:**

- \(PDK-875\) Validate behaviour values when registering a type [\#49](https://github.com/puppetlabs/puppet-resource_api/pull/49) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(PDK-882,PDK-883\) validate only when needed [\#48](https://github.com/puppetlabs/puppet-resource_api/pull/48) ([DavidS](https://github.com/DavidS))
- \(PDK-884\) Handle missing namevars returned by providers [\#47](https://github.com/puppetlabs/puppet-resource_api/pull/47) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- \(PDK-810\) run CI against all the versions [\#46](https://github.com/puppetlabs/puppet-resource_api/pull/46) ([DavidS](https://github.com/DavidS))

## [v1.0.1](https://github.com/puppetlabs/puppet-resource_api/tree/v1.0.1) (2018-03-23)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.0.0...v1.0.1)

**Fixed bugs:**

- Actually implement the promised behavior [\#44](https://github.com/puppetlabs/puppet-resource_api/pull/44) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release prep for v1.0.1 [\#45](https://github.com/puppetlabs/puppet-resource_api/pull/45) ([DavidS](https://github.com/DavidS))
- Release prep for v1.0.0 [\#43](https://github.com/puppetlabs/puppet-resource_api/pull/43) ([da-ar](https://github.com/da-ar))

## [v1.0.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.0.0) (2018-03-23)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.10.0...v1.0.0)

**Implemented enhancements:**

- Improve logging output [\#42](https://github.com/puppetlabs/puppet-resource_api/pull/42) ([DavidS](https://github.com/DavidS))
- \(PDK-797\) Render read\_only values as comments in manifest output [\#41](https://github.com/puppetlabs/puppet-resource_api/pull/41) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(PDK-819\) Ensure checks for mandatory type attributes [\#40](https://github.com/puppetlabs/puppet-resource_api/pull/40) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- Notes on how to build a release [\#39](https://github.com/puppetlabs/puppet-resource_api/pull/39) ([DavidS](https://github.com/DavidS))
- Release prep for v0.10.0 [\#38](https://github.com/puppetlabs/puppet-resource_api/pull/38) ([DavidS](https://github.com/DavidS))

## [v0.10.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.10.0) (2018-03-21)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.9.0...v0.10.0)

**Implemented enhancements:**

- \(PDK-512\) Add support for simple\_get\_filter [\#37](https://github.com/puppetlabs/puppet-resource_api/pull/37) ([da-ar](https://github.com/da-ar))
- \(PDK-822\) Implement proper namevar handling [\#36](https://github.com/puppetlabs/puppet-resource_api/pull/36) ([DavidS](https://github.com/DavidS))
- \(PDK-513\) implement `supports\_noop` [\#31](https://github.com/puppetlabs/puppet-resource_api/pull/31) ([DavidS](https://github.com/DavidS))
- \(PDK-511\) Add canonicalization checking if puppet strict is on. [\#30](https://github.com/puppetlabs/puppet-resource_api/pull/30) ([da-ar](https://github.com/da-ar))
- \(PDK-508\) implement autorequire and friends [\#29](https://github.com/puppetlabs/puppet-resource_api/pull/29) ([DavidS](https://github.com/DavidS))
- Update README with PDK 1.4 commands and messages [\#28](https://github.com/puppetlabs/puppet-resource_api/pull/28) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Cleanups [\#34](https://github.com/puppetlabs/puppet-resource_api/pull/34) ([DavidS](https://github.com/DavidS))
- Cleanup test module [\#33](https://github.com/puppetlabs/puppet-resource_api/pull/33) ([DavidS](https://github.com/DavidS))
- Update to rubocop 0.53.0 [\#32](https://github.com/puppetlabs/puppet-resource_api/pull/32) ([DavidS](https://github.com/DavidS))

## [v0.9.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.9.0) (2018-02-22)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.3.0...v0.9.0)

**Implemented enhancements:**

- \(PDK-536\) Proper datatype parsing and checking [\#23](https://github.com/puppetlabs/puppet-resource_api/pull/23) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- SimpleProvider: fix `is`-lookup and docs [\#24](https://github.com/puppetlabs/puppet-resource_api/pull/24) ([DavidS](https://github.com/DavidS))
- \(main\) Fixup to\_manifest output [\#20](https://github.com/puppetlabs/puppet-resource_api/pull/20) ([shermdog](https://github.com/shermdog))

**Merged pull requests:**

- Release prep v0.9.0 [\#27](https://github.com/puppetlabs/puppet-resource_api/pull/27) ([DavidS](https://github.com/DavidS))
- Add a note on device support to the README [\#26](https://github.com/puppetlabs/puppet-resource_api/pull/26) ([DavidS](https://github.com/DavidS))
- Remove Command API [\#25](https://github.com/puppetlabs/puppet-resource_api/pull/25) ([DavidS](https://github.com/DavidS))

## [v0.3.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.3.0) (2018-02-21)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.2.2...v0.3.0)

**Implemented enhancements:**

- \(FM-6797\) Add debug logging of current and target states [\#21](https://github.com/puppetlabs/puppet-resource_api/pull/21) ([da-ar](https://github.com/da-ar))
- \(PDK-803\) Add YAML output for resources [\#19](https://github.com/puppetlabs/puppet-resource_api/pull/19) ([shermdog](https://github.com/shermdog))
- Edits on resource api readme [\#17](https://github.com/puppetlabs/puppet-resource_api/pull/17) ([clairecadman](https://github.com/clairecadman))

**Fixed bugs:**

- \(PDK-569\) `puppet resource` now displays type name correctly [\#18](https://github.com/puppetlabs/puppet-resource_api/pull/18) ([tphoney](https://github.com/tphoney))

**Merged pull requests:**

- Release prep v0.3.0 [\#22](https://github.com/puppetlabs/puppet-resource_api/pull/22) ([DavidS](https://github.com/DavidS))

## [v0.2.2](https://github.com/puppetlabs/puppet-resource_api/tree/v0.2.2) (2018-01-25)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.2.1...v0.2.2)

**Fixed bugs:**

- make the server parts JRuby compatible [\#15](https://github.com/puppetlabs/puppet-resource_api/pull/15) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release prep v0.2.2 [\#16](https://github.com/puppetlabs/puppet-resource_api/pull/16) ([DavidS](https://github.com/DavidS))

## [v0.2.1](https://github.com/puppetlabs/puppet-resource_api/tree/v0.2.1) (2018-01-24)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.2.0...v0.2.1)

**Fixed bugs:**

- gemspec fixes [\#12](https://github.com/puppetlabs/puppet-resource_api/pull/12) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release prep [\#14](https://github.com/puppetlabs/puppet-resource_api/pull/14) ([DavidS](https://github.com/DavidS))

## [v0.2.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.2.0) (2018-01-23)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.1.0...v0.2.0)

**Implemented enhancements:**

-  \(PDK-703\) Resource API introduction with pdk [\#11](https://github.com/puppetlabs/puppet-resource_api/pull/11) ([DavidS](https://github.com/DavidS))
- \(PDK-746\) have a SimpleProvider for simple cases [\#8](https://github.com/puppetlabs/puppet-resource_api/pull/8) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- Fix params and properties [\#10](https://github.com/puppetlabs/puppet-resource_api/pull/10) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release Prep for 0.2.0 [\#9](https://github.com/puppetlabs/puppet-resource_api/pull/9) ([DavidS](https://github.com/DavidS))
- Small fixes [\#7](https://github.com/puppetlabs/puppet-resource_api/pull/7) ([DavidS](https://github.com/DavidS))

## [v0.1.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.1.0) (2017-11-17)
**Merged pull requests:**

- \(maint\) sort dependencies in gemspec [\#6](https://github.com/puppetlabs/puppet-resource_api/pull/6) ([DavidS](https://github.com/DavidS))
- base\_context processing and processed logging methods [\#5](https://github.com/puppetlabs/puppet-resource_api/pull/5) ([james-stocks](https://github.com/james-stocks))
- Fix resource\_api logging format [\#4](https://github.com/puppetlabs/puppet-resource_api/pull/4) ([james-stocks](https://github.com/james-stocks))
- Add logging action methods to base\_context [\#3](https://github.com/puppetlabs/puppet-resource_api/pull/3) ([james-stocks](https://github.com/james-stocks))
- Logging [\#2](https://github.com/puppetlabs/puppet-resource_api/pull/2) ([james-stocks](https://github.com/james-stocks))
- Workaround missing report back from here to flush\(\) [\#1](https://github.com/puppetlabs/puppet-resource_api/pull/1) ([james-stocks](https://github.com/james-stocks))
