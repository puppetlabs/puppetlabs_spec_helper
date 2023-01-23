## 1.3.1
This is a bugfix release

* Fix a bug when using the library in multiple threads ([HC-105](https://tickets.puppetlabs.com/browse/HC-105))

## 1.3.0
This is a feature release

* Support environment variable lists ([HC-104](https://tickets.puppetlabs.com/browse/HC-104))

## 1.2.6
This is a bugfix release

* Do not ship spec folder with gem ([PA-2942](https://tickets.puppetlabs.com/browse/PA-2942))

## 1.2.5
This is a bugfix release

* Fixed loading files with UTF-8 characters in their file paths

## 1.2.4
This is a feature release.

* Added a cli tool called `hocon` for reading and manipulating hocon files

Note that the version numbers 1.2.0-1.2.3 were not used because of bugs in our
release pipeline we were working out

## 1.1.3
This is a bugfix release.

* Fixed bug where Hocon.parse would throw a ConfigNotResolved error if you passed it a String
  that contained values with substitutions.

## 1.1.2
This is a bugfix release.

* Fixed bug where Hocon::ConfigFactory.parse_file was not handling files with BOMs on Windows,
  causing UTF-8 files to not load properly.

## 1.1.1
This is a bugfix release.

* Fixed a bug where an undefined method `value_type_name` error was being thrown due to
  improper calls to the class method.

## 1.1.0
This is a bugfix/feature release

* Fixed a bug where unrecognized config file extensions caused `Hocon.load` to return an empty
  hash instead of an error.
* Added an optional `:syntax` key to the `Hocon.load` method to explicitly specify the file format
* Renamed internal usage of `name` methods to avoid overriding built in `Object#name` method

## 1.0.1

This is a bugfix release.
The API is stable enough and the code is being used in production, so the version is also being bumped to 1.0.0

* Fixed a bug wherein calling "Hocon.load" would not
  resolve substitutions.
* Fixed a circular dependency between the Hocon and Hocon::ConfigFactory
  namespaces. Using the Hocon::ConfigFactory class now requires you to
  use a `require 'hocon/config_factory'` instead of `require hocon`
* Add support for hashes with keyword keys

## 1.0.0

This version number was burned.

## 0.9.3

This is a bugfix release.

* Fixed a bug wherein inserting an array or a hash into a ConfigDocument would cause
  "# hardcoded value" comments to be generated before every entry in the hash/array.

## 0.9.2

This is a bugfix release

* Fixed a bug wherein attempting to insert a complex value (such as an array or a hash) into an empty
  ConfigDocument would cause an undefined method error.

## 0.9.1

This is a bugfix release.
* Fixed a bug wherein ugly configurations were being generated due to the addition of new objects when a setting
  is set at a path that does not currently exist in the configuration. Previously, these new objects were being
  added as single-line objects. They will now be added as multi-line objects if the parent object is a multi-line
  object or is an empty root object.

## 0.9.0

This is a promotion of the 0.1.0 release with one small bug fix:
* Fixed bug wherein using the `set_config_value` method with some parsed values would cause a failure due to surrounding whitespace

## 0.1.0

This is a feature release containing a large number of changes and improvements

* Added support for concatenation
* Added support for substitutions
* Added support for file includes. Other types of includes are not supported
* Added the new ConfigDocument API that was recently implemented in the upstream Java library
* Improved JSON support
* Fixed a large number of small bugs related to various pieces of implementation
