# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## 1.0.4 - 2021-06-08
- Remove dependency on SortedSet
- Add Ruby 3.0 to Travis and AppVeyor

## 1.0.3 - 2021-01-12
- List failed module install dependencies
- Add Ruby 2.7 to Travis and AppVeyor

## 1.0.2 - 2018-03-13
- Removed i18n/gettext configuration and string externalization. After further consideration we have decided that
  as a library, semantic_puppet should not be attempting to configure global localization state and the localization
  of error messages etc. is the responsibility of the consuming application.
- Added Appveyor CI configuration

## 1.0.1 - 2017-07-01
- Fix bug causing pre-release identifiers being considered invalid when they contained letters but started with a zero

## 1.0.0 - 2017-04-05
- Complete rewrite of the VersionRange to make it compatible with Node Semver
- General speedup of Version (hash, <=>, and to_s in particular)

## 0.1.4 - 2016-07-06
### Changed
- Externalized all user-facing strings using gettext libraries to support future localization.

## 0.1.3 - 2016-05-24
### Added
- Typesafe implementation of ModuleRelease#eql? (and ModuleRelease#==). (PUP-6341)

## 0.1.2 - 2016-04-29
### Added
- Typesafe implementation of Version#eql? (and Version#==). (PUP-6249)

### Fixed
- Homepage URL in gemspec was incorrect. (fiddyspence)

## 0.1.1 - 2015-04-01
### Added
- license information

### Removed
- template entry from CHANGELOG.md

## 0.1.0 - 2015-03-23
### Added
- initial release in concert with current Puppet Module Tool v4.0.0 behavior
