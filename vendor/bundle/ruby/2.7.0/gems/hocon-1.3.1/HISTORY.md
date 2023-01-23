# enterprise_ruby-hocon_bump_and_tag_master - History
## Tags
* [LATEST - 4 Apr, 2017 (b42a72f0)](#LATEST)
* [1.2.4 - 3 Nov, 2016 (5157cc60)](#1.2.4)
* [1.2.3 - 3 Nov, 2016 (cd9a5c8d)](#1.2.3)
* [1.2.2 - 1 Nov, 2016 (4a29c034)](#1.2.2)
* [1.2.1 - 27 Oct, 2016 (b6edea48)](#1.2.1)
* [1.2.0 - 27 Oct, 2016 (1060d251)](#1.2.0)
* [1.1.3 - 12 Oct, 2016 (bf4a7d4b)](#1.1.3)
* [1.1.2 - 15 Jul, 2016 (6041a5c4)](#1.1.2)
* [1.1.1 - 6 Jul, 2016 (5b2c8baa)](#1.1.1)
* [1.1.0 - 1 Jul, 2016 (99b3145e)](#1.1.0)
* [1.0.1 - 16 Mar, 2016 (aa36b692)](#1.0.1)
* [1.0.0 - 16 Feb, 2016 (dc385fe2)](#1.0.0)
* [0.9.3 - 14 Jul, 2015 (7defef59)](#0.9.3)
* [0.9.2 - 30 Jun, 2015 (6b402bc2)](#0.9.2)
* [0.9.1 - 30 Jun, 2015 (e8c2f405)](#0.9.1)
* [0.9.0 - 10 Apr, 2015 (aeab6ab2)](#0.9.0)
* [0.1.0 - 9 Apr, 2015 (bfdb7255)](#0.1.0)
* [0.0.5 - 1 Oct, 2014 (67d264f4)](#0.0.5)
* [0.0.3 - 24 Jul, 2014 (6cd552c3)](#0.0.3)
* [0.0.2 - 24 Jul, 2014 (95dffaea)](#0.0.2)
* [0.0.1 - 16 Mar, 2014 (f7dbca52)](#0.0.1)

## Details
### <a name = "LATEST">LATEST - 4 Apr, 2017 (b42a72f0)

* (GEM) update hocon version to 1.2.5 (b42a72f0)

* Merge pull request #108 from jpinsonault/maint-prepare-for-1.2.5 (50b0087b)


```
Merge pull request #108 from jpinsonault/maint-prepare-for-1.2.5

(MAINT) Change version back 1.2.5.SNAPSHOT
```
* (MAINT) Change version back 1.2.5.SNAPSHOT (40d45c77)


```
(MAINT) Change version back 1.2.5.SNAPSHOT

CI needs the current to be less than the next version to be released
```
* Merge pull request #107 from jpinsonault/PE-18165-support-for-utf8-file-paths (c65941f2)


```
Merge pull request #107 from jpinsonault/PE-18165-support-for-utf8-file-paths

(PE-18165) Support for utf-8 file paths
```
* (MAINT) Prepare for 1.2.5 release (8edf0841)


```
(MAINT) Prepare for 1.2.5 release

Update changelog and version
```
* (PE-18165) Support for utf-8 file paths (a54c93b5)


```
(PE-18165) Support for utf-8 file paths

This commit removes the dependency on Addressable and adds some comments
regarding some screwy areas in the code where we half heartedly tried to
support loading of URIs

It maintains utf-8 file support
```
* Merge pull request #105 from mwbutcher/maint/master/PE-18165_encode_file_URIs_in_order_to_handle_utf-8_chars (e2725955)


```
Merge pull request #105 from mwbutcher/maint/master/PE-18165_encode_file_URIs_in_order_to_handle_utf-8_chars

(PE-18165) encode file URIs to handle utf8 chars
```
* (PE-18165) encode file URIs to handle utf8 chars (51525f43)


```
(PE-18165) encode file URIs to handle utf8 chars

Prior to this change, the hocon parser would
error when give file names like ᚠᛇᚻ.conf or
/tmp/旗本/pe.conf.

This commit URI encodes the filenames to
avoid that issue.
```
* Merge pull request #104 from puppetlabs/rm_cprice404 (ddb4afb2)


```
Merge pull request #104 from puppetlabs/rm_cprice404

remove cprice404
```
* remove cprice404 (f74fb2ca)

* Merge pull request #98 from puppetlabs/theshanx-patch-1 (c532a69e)


```
Merge pull request #98 from puppetlabs/theshanx-patch-1

(maint) Add internal_list key to MAINTAINERS
```
* Merge pull request #102 from jpinsonault/maint-fix-typo-in-readme (ecd2de47)


```
Merge pull request #102 from jpinsonault/maint-fix-typo-in-readme

(MAINT) Fix typo in readme
```
* (MAINT) Fix typo in readme (10961a98)

* Merge pull request #101 from jpinsonault/maint-update-changelog-after-1.2.4-release (c8d543ad)


```
Merge pull request #101 from jpinsonault/maint-update-changelog-after-1.2.4-release

(MAINT) Update changelog for 1.2.4
```
* (MAINT) Update changelog for 1.2.4 (c7a5edf1)


```
(MAINT) Update changelog for 1.2.4

And explain missing version numbers
```
* (maint) Add internal_list key to MAINTAINERS (e327d214)


```
(maint) Add internal_list key to MAINTAINERS

This change adds a reference to the Google group the maintainers are associated with.
```
### <a name = "1.2.4">1.2.4 - 3 Nov, 2016 (5157cc60)

* (HISTORY) update ruby-hocon history for gem release 1.2.4 (5157cc60)

* (GEM) update hocon version to 1.2.4 (67ff0795)

* Merge pull request #100 from jpinsonault/maint-update-version-to-1.2.4 (3a493130)


```
Merge pull request #100 from jpinsonault/maint-update-version-to-1.2.4

(MAINT) Update version to 1.2.4
```
* (MAINT) Update version to 1.2.4 (958326d4)

### <a name = "1.2.3">1.2.3 - 3 Nov, 2016 (cd9a5c8d)

* (HISTORY) update ruby-hocon history for gem release 1.2.3 (cd9a5c8d)

* (GEM) update hocon version to 1.2.3 (f2f3e235)

* Merge pull request #99 from jpinsonault/maint-update-version-to-1.2.3 (18324c6d)


```
Merge pull request #99 from jpinsonault/maint-update-version-to-1.2.3

(MAINT) Update version 1.2.3
```
* (MAINT) Update version 1.2.3 (e7be1d78)

### <a name = "1.2.2">1.2.2 - 1 Nov, 2016 (4a29c034)

* (HISTORY) update ruby-hocon history for gem release 1.2.2 (4a29c034)

* (GEM) update hocon version to 1.2.2 (5cf6b037)

* Merge pull request #97 from jpinsonault/maint-update-version-for-release (e973ee34)


```
Merge pull request #97 from jpinsonault/maint-update-version-for-release

(MAINT) Update version for release
```
* (MAINT) Update version for release (e81fecf9)

### <a name = "1.2.1">1.2.1 - 27 Oct, 2016 (b6edea48)

* (HISTORY) update ruby-hocon history for gem release 1.2.1 (b6edea48)

* (GEM) update hocon version to 1.2.1 (0e06af2f)

* Merge pull request #96 from jpinsonault/maint-update-version-to-1.2.1.SNAPSHOT (418d5e24)


```
Merge pull request #96 from jpinsonault/maint-update-version-to-1.2.1.SNAPSHOT

(MAINT) Update version to 1.2.1.SNAPSHOT
```
* (MAINT) Update version to 1.2.1.SNAPSHOT (20d34a33)

### <a name = "1.2.0">1.2.0 - 27 Oct, 2016 (1060d251)

* (HISTORY) update ruby-hocon history for gem release 1.2.0 (1060d251)

* (GEM) update hocon version to 1.2.0 (33a9edef)

* Merge pull request #95 from jpinsonault/maint-fix-pre-release-version-string (dba994b3)


```
Merge pull request #95 from jpinsonault/maint-fix-pre-release-version-string

(MAINT) Fix version string
```
* (MAINT) Fix version string (622fb2ab)

* Merge pull request #94 from jpinsonault/maint-update-release-date (41673be4)


```
Merge pull request #94 from jpinsonault/maint-update-release-date

(MAINT) Update date in gemfile for 1.2.0 release
```
* (MAINT) Update date in gemfile for 1.2.0 release (25e834fc)

* Merge pull request #93 from jpinsonault/maint-prepare-for-1.2.0-release (c0ab30b1)


```
Merge pull request #93 from jpinsonault/maint-prepare-for-1.2.0-release

(MAINT) Update version and changelog for 1.2.0 release
```
* (MAINT) Update version and changelog for 1.2.0 release (d4ac81ac)

* Merge pull request #92 from jpinsonault/maint-revert-moving-version.rb (bd5a065e)


```
Merge pull request #92 from jpinsonault/maint-revert-moving-version.rb

Revert "(MAINT) Move version.rb to work with ci"
```
* Revert "(MAINT) Move version.rb to work with ci" (a17015fc)


```
Revert "(MAINT) Move version.rb to work with ci"

This reverts commit 5be440a433141e7dab5534d2309282d0865adca7.
```
* Merge pull request #90 from puppetlabs/add-issue-tracker-link (b046a116)


```
Merge pull request #90 from puppetlabs/add-issue-tracker-link

Include link to Jira issue tracker in README
```
* Merge pull request #91 from jpinsonault/maint-move-version.rb-for-ci (dd9753d2)


```
Merge pull request #91 from jpinsonault/maint-move-version.rb-for-ci

(MAINT) Move version.rb to work with ci
```
* (MAINT) Move version.rb to work with ci (5be440a4)


```
(MAINT) Move version.rb to work with ci

Jenkins expects the version.rb file to be under lib/<github_project>/version.rb
```
* Include link to Jira issue tracker in README (75609de4)

* Merge pull request #86 from jpinsonault/hc-92-add-cli-tool-for-hocon (ea0ddcae)


```
Merge pull request #86 from jpinsonault/hc-92-add-cli-tool-for-hocon

[WIP] (HC-92) Add cli tool for hocon
```
* (HC-92) Have unset throw an error on missing paths (2577e8fe)


```
(HC-92) Have unset throw an error on missing paths

Refactor the way errors are handled. Rather than catching the hocon
parser errors, we now raise our own error to make things clearer

Add tests for new exception
```
* (HC-92) Remove flock calls (14c548b5)

* (MAINT) Update CHANGELOG for 1.1.3 (f02b161a)

* (HC-92) Fix version require for ruby 1.9 (d21fb360)

* (HC-92) Move version string to Hocon::Version module (ca9de704)

* (HC-92) Add -f option, update docs (afe75db5)

* (HC-92) Lock files while reading/writing (6271c25e)

* (HC-92) Update readme with CLI docs (1afa6c2c)

* (HC-92) Update optparse banner with more info (2a047009)

* (HC-92) Make new render option optional (06429cac)

* (HC-92) Add tests for new render option (2762f01f)


```
(HC-92) Add tests for new render option

Adds tests for key_value_separator render option
```
* (HC-92) Add cli tests for setting complex types (3d548f33)

* (HC-92) Add key_value_separator render option (b12a822c)


```
(HC-92) Add key_value_separator render option

Also updates the CLI tool to use the colon separator in the set subcommand
```
* (HC-92) Update version to 1.2.0 (4746078e)

* (HC-92) Whitespace (b9b65fd5)

* (HC-92) Remove default space before colons in maps (12a31ca6)

* (HC-92) Add spec tests for cli functions (8b06d660)

* (HC-92) Improve modularity (846040d0)

* (HC-92) Add json output support (6a203bf3)

* (HC-92) Better error handling (88a6abca)

* (HC-92) Add --out-file support (07bdef54)

* (HC-92) Move cli code to lib dir (fb0483fc)

* (HC-92) Add STDIN support (61b872c5)

* (HC-92) Add CLI tool for hocon (21d5f01d)

### <a name = "1.1.3">1.1.3 - 12 Oct, 2016 (bf4a7d4b)

* Merge pull request #88 from cprice404/bug/master/parse-with-substitutions (bf4a7d4b)


```
Merge pull request #88 from cprice404/bug/master/parse-with-substitutions

Fix bug in `Hocon.parse` with substitutions
```
* Fix bug in `Hocon.parse` with substitutions (07b265b9)


```
Fix bug in `Hocon.parse` with substitutions

Currently, if you call `Hocon.parse` with a string that contains
substitutions, you will get a `ConfigNotResolvedError`.

We had this issue with `Hocon.load` earlier, and modified it to
include the code necessary to resolve the config object before
returning it.  However, we didn't make the same changes for `parse`,
so the behavior actually diverged between the two.

This commit fixes up `parse` in the same way that we previously
fixed up `load`.
```
* Merge pull request #85 from cprice404/maint/master/200-add-maintainers (d98ad200)


```
Merge pull request #85 from cprice404/maint/master/200-add-maintainers

(200) Add MAINTAINERS
```
* (200) Add MAINTAINERS (8119f366)

* Merge pull request #84 from jpinsonault/maint-add-ruby-gems-widget (a8318435)


```
Merge pull request #84 from jpinsonault/maint-add-ruby-gems-widget

(MAINT) Add rubygems version widget
```
* (MAINT) Add rubygems version widget (3b9bb37e)

### <a name = "1.1.2">1.1.2 - 15 Jul, 2016 (6041a5c4)

* Merge pull request #83 from jpinsonault/maint-update-changelog-for-1.1.2 (6041a5c4)


```
Merge pull request #83 from jpinsonault/maint-update-changelog-for-1.1.2

(MAINT) Update changelog/version for 1.1.2 release
```
* (MAINT) Update changelog/version for 1.1.2 release (947e6aa4)

* Merge pull request #82 from Iristyle/ticket/master/HC-82-parse-files-as-utf8-with-boms (a58adc87)


```
Merge pull request #82 from Iristyle/ticket/master/HC-82-parse-files-as-utf8-with-boms

(HC-82) Enable UTF-8 with BOM parsing
```
* (HC-82) Add spec for UTF-8 filenames (b0d702c1)


```
(HC-82) Add spec for UTF-8 filenames

 - Hocon does not currently handle UTF-8 filenames properly
```
* (HC-82) Remove invalid BOM spec (9a5cabea)


```
(HC-82) Remove invalid BOM spec

 - A skipped test exists for validating a string can be passed to
   parse_string that starts with a UTF8 BOM \uFEFF

 - However, when comparing this to the Ruby JSON parser, that parser
   also doesn't handle this seemingly edge case.  Arguably, by the
   time a string read from a file is passed to a parsing engine, it
   will be in the correct encoding, and will have leading BOMs
   trimmed off.

   For reference, Ruby JSON behavior:

   [1] pry(main)> require 'json'
   => true

   [2] pry(main)> json = "\uFEFF{ \"foo\": \"bar\" }"
   => "{ \"foo\": \"bar\" }"

   [3] pry(main)> JSON.parse(json)
   JSON::ParserError: 757: unexpected token at '{ "foo": "bar" }'
   from /usr/local/opt/rbenv/versions/2.1.9/lib/ruby/2.1.0/json/common.rb:155:in `parse'
```
* (HC-82) Add additional file encoding specs (9e04970e)


```
(HC-82) Add additional file encoding specs

 - Show that UTF-8 content is properly handled
 - Show that UTF-16 content is not yet supported
```
* (HC-82) Enable UTF-8 with BOM parsing (8ccf6625)


```
(HC-82) Enable UTF-8 with BOM parsing

 - Previously Hocon::ConfigFactory.parse_file did not specify an
   encoding, and didn't allow for files with UTF-8 BOMs on Windows.

   In reality, HOCON config files should be detected by their BOM and
   treated as UTF-8, UTF-16LE, UTF-16BE, UTF-32LE or UTF-32BE based on
   the presence of the BOM, with a fallback to UTF-8 when one is not
   present, based on RFC 4627 at https://www.ietf.org/rfc/rfc4627.txt

   This fix is a bit naive as it may improperly load HOCON config
   files on Windows which are UCS-2 (a precursor to UTF-16LE). Its
   recommended that this be addressed later in a better File parsing
   scheme that peeks at the first few bytes of the file to determine
   the encoding correctly.
```
### <a name = "1.1.1">1.1.1 - 6 Jul, 2016 (5b2c8baa)

* Merge pull request #81 from janelu2/master (5b2c8baa)


```
Merge pull request #81 from janelu2/master

(MAINT) update CHANGELOG.md and version number for z release of 1.1.1
```
* (MAINT) update CHANGELOG.md and version number for z release of 1.1.1 (582cd7e2)

* Merge pull request #80 from janelu2/master (17ecc8d4)


```
Merge pull request #80 from janelu2/master

(HC-81) Fix undefined method `value_type_name' error
```
* (HC-81) Add tests and fix value_type_name calls (466ca82a)


```
(HC-81) Add tests and fix value_type_name calls

(MAINT) fix test to correctly call the wrong error

(MAINT) add require to config_value_type and use alias
```
### <a name = "1.1.0">1.1.0 - 1 Jul, 2016 (99b3145e)

* Merge pull request #78 from jpinsonault/maint-update-changelog-for-release (99b3145e)


```
Merge pull request #78 from jpinsonault/maint-update-changelog-for-release

(MAINT) Update changelog and version for release
```
* (MAINT) Fix changelog version (aa3fef17)

* Merge pull request #79 from janelu2/master (17d96e4b)


```
Merge pull request #79 from janelu2/master

(MAINT) update readme
```
* (MAINT) update readme (3123b670)

* (MAINT) Update changelog and version for release (213e10f8)


```
(MAINT) Update changelog and version for release

Update changelog
Bump version to 1.1.0
Update gitignore with Gemfile.lock
```
* Merge pull request #77 from cprice404/bug/master/HC-80-dont-shadow-ruby-class-module-name (61194207)


```
Merge pull request #77 from cprice404/bug/master/HC-80-dont-shadow-ruby-class-module-name

(HC-80) Don't shadow ruby Class/Module#name method
```
* Merge pull request #76 from cprice404/maint/master/HC-79-support-format-arg-in-load (c0c88698)


```
Merge pull request #76 from cprice404/maint/master/HC-79-support-format-arg-in-load

(HC-79) support :syntax arg in load
```
* (MAINT) Change variable name for readability (cd3505ed)

* (HC-80) Don't shadow ruby Class/Module#name method (4f7c8ccc)


```
(HC-80) Don't shadow ruby Class/Module#name method

Prior to this commit, there were a few places in the code where
we'd ported over a class-or-module-level method named `name` from
the upstream library.  This isn't a good idea in Ruby because it
results in shadowing of the built in Ruby methods Class#name and
Module#name.  This was causing problems for some users, e.g. in
cases where reflection is being used to examine classes.

In this commit we rename all such methods to something more specific,
and replace the calls to the old names with calls to the new names.
```
* (HC-79) support `:syntax` option in simple `load` (a5663ca6)


```
(HC-79) support `:syntax` option in simple `load`

This commit adds support for an optional `opts` map to be passed
in to the simple `load` method.  If provided, this map may contain
a `:syntax` key that explicitly specifies which config format/syntax
the user expects the file to be in.

This provides a way for users to load files whose file extension
doesn't match the built-in expectations for which file extensions
use which syntaxes.

The commit also provides some error checking for the case where
an explicit `:syntax` is not passed in, and the file extension
isn't recognized.  In this case, we will throw an error now, rather
than silently returning an empty map like we did in the past.

Finally, this commit adds some notes to the docs/example usage,
indicating how to pass in an explicit syntax.
```
* (MAINT) separate ruby tests from upstream tests (3cd0f049)

* Merge pull request #74 from karenvdv/server-1300-add-maintainers (ffc0e143)


```
Merge pull request #74 from karenvdv/server-1300-add-maintainers

Add maintainers section
```
* Add maintainers section (6fec1cdc)

### <a name = "1.0.1">1.0.1 - 16 Mar, 2016 (aa36b692)

* Update for 1.0.1 release (aa36b692)

* Update date for 1.0.0 release (9cbb6175)

### <a name = "1.0.0">1.0.0 - 16 Feb, 2016 (dc385fe2)

* Merge pull request #72 from jpinsonault/maint-bump-version-to-1.0.0 (dc385fe2)


```
Merge pull request #72 from jpinsonault/maint-bump-version-to-1.0.0

(MAINT) bump and relabel version 0.9.4 to 1.0.0
```
* (MAINT) Add link to readme (d6312759)

* (MAINT) Update gemfile.lock (a9b721b6)

* (MAINT) Whitespace - Cleanup README (920ffafb)

* (MAINT) Bump and relabel 0.9.4 to 1.0.0 (e129b2ee)


```
(MAINT) Bump and relabel 0.9.4 to 1.0.0

0.9.4 introduced changes that require some users to modify their require
statements due to bugfixes. In addition the API is stable enough to consider this a 1.0.0
release

1.0.0 Changlog:
This is a bugfix release.
The API is stable enough and the code is being used in production, so the version is also being bumped to 1.0.0

* Fixed a bug wherein calling "Hocon.load" would not
  resolve substitutions.
* Fixed a circular dependency between the Hocon and Hocon::ConfigFactory
  namespaces. Using the Hocon::ConfigFactory class now requires you to
  use a `require 'hocon/config_factory'` instead of `require hocon`
* Add support for hashes with keyword keys
```
* Merge pull request #71 from fpringvaldsen/maint/changelog (2b55e3b7)


```
Merge pull request #71 from fpringvaldsen/maint/changelog

Fix changelog for 0.9.4
```
* Fix changelog for 0.9.4 (7e417107)


```
Fix changelog for 0.9.4

Add changes that went into the 0.9.4 release that weren't
listed in the changelog.
```
* (MAINT) Update Gemfile.lock (d9f1d4c8)

* (MAINT) Update for 0.9.4 release (ec909659)

* Merge pull request #70 from fpringvaldsen/maint/load-issue (1ffa268a)


```
Merge pull request #70 from fpringvaldsen/maint/load-issue

(MAINT) Fix Hocon.load substitution issue
```
* (MAINT) Fix Hocon.load substitution issue (31321f0b)


```
(MAINT) Fix Hocon.load substitution issue

Previously, Hocon.load was calling into the
ConfigFactory.parse_file method. However, the `parse` methods
in ConfigFactory do not resolve substitutions, as that is the
intent of the `load` methods.

This commit updates the Hocon.load method to call into
ConfigFactory.load_file. It also updates the readme to explain
the usage of ConfigDocuments, and adds a comment to explain
that the `load` methods in ConfigFactory should be used if
substitutions are present
```
* Merge pull request #68 from krjackso/master (f9f29a3f)


```
Merge pull request #68 from krjackso/master

Fix typo when referencing GENERIC OriginType
```
* Fix typo when referencing GENERIC OriginType (0d1a65fc)

* Merge pull request #66 from traylenator/addspec (c9f56235)


```
Merge pull request #66 from traylenator/addspec

Add spec tests to gem file. Fixes #65
```
* Add spec tests to gem file. Fixes #65 (573da794)

* Merge pull request #64 from cprice404/maint/master/fix-circular-deps (618592a1)


```
Merge pull request #64 from cprice404/maint/master/fix-circular-deps

(HC-24) Use simple API in README, fix circular deps
```
* (HC-24) Use simple API in README, fix circular deps (3783f305)


```
(HC-24) Use simple API in README, fix circular deps

This commit updates the README to show the simpler version of the
API for basic read operations.

It also fixes some circular dependencies that were causing the
example code for the ConfigDocumentFactory not to work properly.
```
* Merge pull request #62 from fpringvaldsen/improvement/TK-251/keyword-keys (0e7216c4)


```
Merge pull request #62 from fpringvaldsen/improvement/TK-251/keyword-keys

(TK-251) Convert symbol keys to strings
```
* (TK-251) Process nested hashes (724f792d)


```
(TK-251) Process nested hashes

When converting a Hashes symbol keys to strings, also process
any nested hashes that are present.
```
* (TK-251) Convert symbol keys to strings (89f57cc1)


```
(TK-251) Convert symbol keys to strings

When parsing a Hash in ConfigValueFactory, automatically convert
all symbol keys to strings.
```
### <a name = "0.9.3">0.9.3 - 14 Jul, 2015 (7defef59)

* Update Changelog and Gemspec for 0.9.3 (7defef59)

* Merge pull request #61 from fpringvaldsen/bug/TK-249/bad-comments (be17f2a4)


```
Merge pull request #61 from fpringvaldsen/bug/TK-249/bad-comments

(TK-249) Remove unnecessary comments in output
```
* (TK-249) Remove unnecessary comments in output (e893d6fc)


```
(TK-249) Remove unnecessary comments in output

Remove unnecessary "# hardcoded value" comments that were being
generated when inserting a hash or an array into a ConfigDocument.
```
### <a name = "0.9.2">0.9.2 - 30 Jun, 2015 (6b402bc2)

* Update CHANGELOG and gemspec for 0.9.2 (6b402bc2)

* Merge pull request #59 from fpringvaldsen/maint/undefined-method-fix (96499050)


```
Merge pull request #59 from fpringvaldsen/maint/undefined-method-fix

(MAINT) Fix undefined method bug
```
* (MAINT) Fix undefined method bug (a47ee9b0)


```
(MAINT) Fix undefined method bug

Fix an undefined method bug that was occurring when attempting to
add a complex value into an empty root object.
```
### <a name = "0.9.1">0.9.1 - 30 Jun, 2015 (e8c2f405)

* Update CHANGELOG and gemspec for 0.9.1 (e8c2f405)

* Merge pull request #58 from fpringvaldsen/bug/TK-246/single-line-config (c4bfc3c0)


```
Merge pull request #58 from fpringvaldsen/bug/TK-246/single-line-config

(TK-246) Fix single-line config bug
```
* (TK-246) Fix single-line config bug (9305707b)


```
(TK-246) Fix single-line config bug

Previously there was a bug wherein building out a config starting
from an empty ConfigDocument would cause the entire config to
exist on a single line. Fix this bug by modifying the addition of
new maps along a path to add multi-line maps instead of
single-line maps if the object being added to is an empty root or
a multi-line object.
```
* Merge pull request #57 from cprice404/maint/master/improve-error-messages-for-problem-tokens (afeed2a0)


```
Merge pull request #57 from cprice404/maint/master/improve-error-messages-for-problem-tokens

(MAINT) Improve error messages for Problem tokens
```
* (MAINT) Improve error messages for Problem tokens (be4a9320)


```
(MAINT) Improve error messages for Problem tokens

Prior to this commit, the `Problem` token type called
`to_s` on an internal `StringIO` object when building
up an error string to return to the user.  Calling
`to_s` on a `StringIO` just causes it to print out,
basically, `#<StringIO...>`, so you don't get the
useful error message.

This patch changes the code to call `string` instead,
which returns a much more useful error message.
```
### <a name = "0.9.0">0.9.0 - 10 Apr, 2015 (aeab6ab2)

* Merge pull request #56 from jpinsonault/maint-update-for-0.9.0-release (aeab6ab2)


```
Merge pull request #56 from jpinsonault/maint-update-for-0.9.0-release

(MAINT) Update for 0.9.0 release
```
* (MAINT) Update for 0.9.0 release (a139e789)

* Merge pull request #55 from fpringvaldsen/maint/empty-doc-test (5b7b7d8f)


```
Merge pull request #55 from fpringvaldsen/maint/empty-doc-test

(MAINT) Add empty document insertion test
```
* (MAINT) Add additional ConfigValue insertion test (9d307477)


```
(MAINT) Add additional ConfigValue insertion test

Add an additional test for inserting a ConfigValue into a
ConfigDocument. Fix an issue wherein this would fail as the
rendered result of ConfigValue was not having whitespace trimmed.
```
* (MAINT) Add empty document insertion test (62394f9c)


```
(MAINT) Add empty document insertion test

Add a test for insertion into an empty ConfigDocument.
```
### <a name = "0.1.0">0.1.0 - 9 Apr, 2015 (bfdb7255)

* (MAINT) Update gemspec for 0.1.0 release (bfdb7255)

* (MAINT) Remove SimpleConfigDocument require (bea56c92)


```
(MAINT) Remove SimpleConfigDocument require

Remove the SimpleConfigDocument require from the ConfigDocument
spec, as this was causing an issue wherein Parseable would work
properly even though it needed to require SimpleConfigDocument.
```
* (MAINT) Fix uninitialized constant error (fd2abd12)

* Merge pull request #53 from fpringvaldsen/task/TK-188/refactor-parser (30c5feee)


```
Merge pull request #53 from fpringvaldsen/task/TK-188/refactor-parser

(TK-188) Refactor Parser
```
* Merge pull request #54 from jpinsonault/tk-161-port-public-api-tests (0a4fcbe0)


```
Merge pull request #54 from jpinsonault/tk-161-port-public-api-tests

(TK-161) port public api tests
```
* Added test for load_file_with_resolve_options (7afc6053)

* Addressed PR feedback (029db783)

* Merge pull request #52 from fpringvaldsen/task/TK-187/port-ConfigDocument (73471f1b)


```
Merge pull request #52 from fpringvaldsen/task/TK-187/port-ConfigDocument

(TK-187) Port ConfigDocument and tests
```
* (MAINT) Fix typos (f3102ef8)


```
(MAINT) Fix typos

Fix typos in comment and test string.
```
* (MAINT) Fix failing ConfigValue test (9ddbc290)


```
(MAINT) Fix failing ConfigValue test

Fix bug with the rendering of SimpleConfigList that was causing
a skipped ConfigValue test to fail.
```
* Refactor Parser (fdc74366)


```
Refactor Parser

Refactor the Parser class into ConfigParser, and change it to
parse ConfigNodes rather than Tokens. Change Parseable to first
parse a ConfigDocument, then use that to parse a Config.
```
* (MAINT) Clean-up loops (5d10c6fc)


```
(MAINT) Clean-up loops

Clean up certain loops in ConfigNode and ConfigDocument
implementations to be more ruby-esque.
```
* (TK-187) Port ConfigDocument tests (df22b9f7)


```
(TK-187) Port ConfigDocument tests

Port all ConfigDocument tests down to ruby-hocon and get them
passing.
```
* Merge pull request #51 from fpringvaldsen/task/TK-186/port-ConfigNode (63c8907a)


```
Merge pull request #51 from fpringvaldsen/task/TK-186/port-ConfigNode

(TK-186) Port ConfigNode tests
```
* (TK-187) Port ConfigDocument classes/interfaces (1b8f5eea)


```
(TK-187) Port ConfigDocument classes/interfaces

Port the ConfigDocument classes and interfaces from the upstream
library, sans tests.
```
* (TK-186) Update comment on AbstractConfigNodeValue (391d1c89)


```
(TK-186) Update comment on AbstractConfigNodeValue

Update the comment on the AbstractConfigNodeValue to reflect that
the module is unnecessary in Ruby and is being preserved solely
for consistency.
```
* (TK-186) Make abstract classes into modules (00a7d5dd)


```
(TK-186) Make abstract classes into modules

Change all ConfigNode classes that are abstract in the upstream
library into modules. Change the ConfigNode class to a module.
```
* (TK-186) Fix typo in comment_text method name (73da7db5)


```
(TK-186) Fix typo in comment_text method name

Change the commentText method to comment_text.
```
* (TK-187) Port ConfigDocumentParser tests (19134ddd)


```
(TK-187) Port ConfigDocumentParser tests

Port all tests for ConfigDocumentParser and ensure they are
passing.
```
* (TK-187) Port ConfigDocumentParser (18f55f46)


```
(TK-187) Port ConfigDocumentParser

Port the ConfigDocumentParser class (sans tests) from the
upstream library.
```
* (TK-161) Port Public API tests to ruby-hocon (03bc79a1)

* (MAINT) Fix issue with concatenation tests (14615490)

* (TK-186) Port ConfigNode tests (f5197a2a)


```
(TK-186) Port ConfigNode tests

Port all the ConfigNode tests in the upstream library. Make
various bugfixes to get the tests passing.
```
* Merge pull request #50 from KevinCorcoran/errmagerhd (798ab05a)


```
Merge pull request #50 from KevinCorcoran/errmagerhd

(TK-162) enable concatenation test cases + fixes
```
* (TK-186) Implement ConfigNode classes (3600a2be)


```
(TK-186) Implement ConfigNode classes

Implement all the various ConfigNode classes from the upstream
library.
```
* Merge pull request #48 from jpinsonault/tk-159-round-three-config-value-tests (5e95a622)


```
Merge pull request #48 from jpinsonault/tk-159-round-three-config-value-tests

(TK-159) Final round of config value tests
```
* Addressed PR feedback (d5c04edc)

* Merge pull request #49 from cprice404/maint/master/excepton-typo (7d31e86f)


```
Merge pull request #49 from cprice404/maint/master/excepton-typo

(MAINT) fix 'excepton' typo
```
* (MAINT) fix 'excepton' typo (2f705314)

* Merge pull request #47 from cprice404/feature/master/TK-160-more-conf-parser-tests (e73f00fb)


```
Merge pull request #47 from cprice404/feature/master/TK-160-more-conf-parser-tests

(TK-160) More config parser tests
```
* Addressed PR feedback (a5e314da)

* (TK-160) Improve comments re: BOM tests (a054355b)

* Merge pull request #46 from KevinCorcoran/delayed-merge (c2a58a41)


```
Merge pull request #46 from KevinCorcoran/delayed-merge

implement rest of CDMO + other bugfixes
```
* (TK-160) Finished implementing conf parser tests (d19ea3bc)

* (TK-160) Port multi-field comment tests (c959e2c9)

* (TK-160) Port comment tests (dbea64ae)

* (TK-160) Port more conf parser tests (07a3f335)

* Merge pull request #45 from cprice404/feature/master/TK-160-more-include-parser-tests (c3b622e0)


```
Merge pull request #45 from cprice404/feature/master/TK-160-more-include-parser-tests

(TK-160) fix remaining "valid conf" parser tests
```
* (TK-160) Fix typos (ac6f9c44)

* (TK-162) enable concatenation test cases + fixes (de643885)


```
(TK-162) enable concatenation test cases + fixes

Un-comment the remaining concatenation test cases that were still commented-out
and fix bugs.  Also added 'inspect' implementations and use short class names to
make trace output match upstream, and re-wrote various bits of code to correspond
more closely to upstream.
```
* (maint) port rest of MemoKey and fix a couple bugs (7374d543)

* (maint) sync SimpleConfigObject.== with upstream (3f4d7fe0)

* (maint) sync ConfigDelayedMergeObject w/ upstream (df402953)

* (TK-159) Final round of config value tests (cfdaa58d)


```
(TK-159) Final round of config value tests

Implemented AbstractConfigValue#at_path/at_key
```
* Merge pull request #44 from KevinCorcoran/finish-concat-test-2 (a01c2214)


```
Merge pull request #44 from KevinCorcoran/finish-concat-test-2

(TK-162) concat tests
```
* (maint) add comment about Ruby vs. Java integers (34fca36e)

* (TK-160) More config parser tests (b3b48fd0)

* (MAINT) Remove code related to '.properties' files (69367ad0)

* (TK-160) Get `include` "valid conf" parser tests passing (bea8a481)

* (TK-162) comment-out failing concat test cases (2fdb2621)

* Merge pull request #43 from cprice404/feature/master/TK-160-more-valid-conf-parser-tests (1da67e76)


```
Merge pull request #43 from cprice404/feature/master/TK-160-more-valid-conf-parser-tests

(TK-160) more valid conf parser tests
```
* (TK-160) re-enable += tests, they are passing now (fd646c39)

* Merge pull request #40 from cprice404/maint/master/re-sync-parser-and-tokenizer (903c9bdd)


```
Merge pull request #40 from cprice404/maint/master/re-sync-parser-and-tokenizer

(MAINT) Update Parser to match latest upstream
```
* (MAINT) Fix bugs and port ConfigNode interface (efcbacea)

* Merge pull request #42 from KevinCorcoran/config-string (710b3f80)


```
Merge pull request #42 from KevinCorcoran/config-string

(maint) sync ConfigString with upstream
```
* (MAINT) Sync ConfigDelayedMerge (4e389d3b)

* (MAINT) re-sync `Path` class (853b447a)

* Merge pull request #41 from KevinCorcoran/fix-null-in-concat (146f22bf)


```
Merge pull request #41 from KevinCorcoran/fix-null-in-concat

Fix null in concat
```
* (maint) sync ConfigString with upstream (e13ea5a7)


```
(maint) sync ConfigString with upstream

Also, replace calls to ConfigString.new with Quoted/Unquoted.
```
* (TK-162) finish porting concatenation tests (7a6f8d75)

* Merge pull request #39 from KevinCorcoran/resolve-source-and-concat-test (b1874e34)


```
Merge pull request #39 from KevinCorcoran/resolve-source-and-concat-test

port ResolveSource and concat test case
```
* (maint) port concatenation tests and fix bugs (f62a49c8)

* (maint) small refactor to match upstream (6d2474df)


```
(maint) small refactor to match upstream

Re-write a few bits of SimpleConfigObject.render_value_to_sb to
make it more closely match the upstream version.
```
* (maint) fix bad reference to self.class (f77a983d)

* Merge pull request #36 from KevinCorcoran/sync-up-config-concat (6ac66904)


```
Merge pull request #36 from KevinCorcoran/sync-up-config-concat

(maint) sync ConfigConcatenation with upstream
```
* (maint) fix typo and log message (f33e5b31)

* Merge pull request #37 from jpinsonault/tk-159-round-two-config-value-tests (9c6b2333)


```
Merge pull request #37 from jpinsonault/tk-159-round-two-config-value-tests

(TK-159) Round Two of ConfigValue tests
```
* (maint) use self.class instead of class name (d5c8046b)

* (maint) fix method name to match upstream (8a5b1b12)

* Merge pull request #35 from cprice404/maint/master/flesh-out-simple-config-list (517ac3a3)


```
Merge pull request #35 from cprice404/maint/master/flesh-out-simple-config-list

(MAINT) Flesh out SimpleConfigList
```
* Addressed PR feedback (a142e824)

* (MAINT) Fix immutable exception type, bugs in SCOrigin (c1696790)


```
(MAINT) Fix immutable exception type, bugs in SCOrigin

This commit does the following:

* Changes the exception type for the `we_are_immutable` cases
  to use a new `UnsupportedOperationError`, to make the behavior
  model the Java version more closely.
* Fix a couple of bugs in the ==/hash methods of SimpleConfigOrigin
```
* (MAINT) Update Parser to match latest upstream (f4b4ee62)

* (TK-162) additional concatenation test case (2650e4b2)


```
(TK-162) additional concatenation test case

... and the changes to the production code required for it to pass.
```
* (maint) sync ResolveSource with upstream version (153c91e3)

* (MAINT) Flesh out SimpleConfigOrigin (8179f4e5)

* Merge pull request #34 from cprice404/maint/master/flesh-out-simple-config-object (1b4976c4)


```
Merge pull request #34 from cprice404/maint/master/flesh-out-simple-config-object

(MAINT) flesh out simple config object
```
* (MAINT) Flesh out SimpleConfigList (35ec6306)

* (maint) sync ConfigConcatenation with upstream (ef2dbdff)

* (MAINT) Change `RuntimeError` to `ConfigError`. (e805e83c)

* (TK-160) Get most 'valid conf' parser tests passing (7c93a5b3)


```
(TK-160) Get most 'valid conf' parser tests passing

This commit fixes a ton of bugs and syncs some classes necessary
to get most of the 'valid conf' parser tests passing.
```
* (MAINT) Another fix to a bad line in SCO (3b638f5c)

* (MAINT) fix bad line of port of SimpleConfigObject (c24850e3)

* (TK-160) Add `it` block for test counts (af7cfc2e)


```
(TK-160) Add `it` block for test counts

Adding this `it` block causes rspec to correctly update the
test counts based on these invalid configuration parsing tests.
```
* (MAINT) Finish porting / clean up AbstractConfigObject (bad5d034)

* Merge pull request #33 from cprice404/feature/master/TK-160-port-conf-parser-tests (f980ff46)


```
Merge pull request #33 from cprice404/feature/master/TK-160-port-conf-parser-tests

(TK-160) Port minimal `include` functionality
```
* (TK-160) fix whitespace, add cause to MalformedUrlError (0d9afb51)

* (MAINT) Finish porting / clean up AbstractConfigValue (ee244518)

* (MAINT) Finish porting / clean up SimpleConfigObject (659bbcda)

* (TK-160) Fix config parse tests related to config_reference (d7f35022)

* Merge pull request #32 from jpinsonault/tk-159-partial-set-of-config-value-tests (82648f63)


```
Merge pull request #32 from jpinsonault/tk-159-partial-set-of-config-value-tests

(TK-159) Partial set of ConfigValue tests implemented
```
* Added another include_all? test, fixed description typo (60c5f83a)

* (TK-160) Got most of the `reference` tests passing. (4ce36feb)

* (TK-160) Port minimal `include` functionality (04989412)


```
(TK-160) Port minimal `include` functionality

This commit re-enables some disabled config parser tests that
had been failing due to missing functionality around HOCON's
`include` capabilities.  It also includes a minimal port
of all of the `include` functionality that was required
to get the tests passing.
```
* Addressed PR comments (16ccac67)


```
Addressed PR comments

Implemented and added test for SimpleConfigList#include_all?
Made ConfigReference#not_resolved private and not static
Fixed typo in ConfigReference#relativized
ConfigDelayedMergeObject#unwrapped now throws not_resolved
Made various methods private to match Java version
SimpleConfigObject#map_equals: got rid of confusing ugly lambda, uses sorted keys now
No longer flay the ConfigDelayedMerge objects
```
* Using self in test_utils (efa3151b)

* (TK-159) More ConfigValue tests (5d60b6d0)


```
(TK-159) More ConfigValue tests

Another set of tests for config_value_spec. There will be at least one more after this one.

Added a few methods to AbstractConfigObject
Made the definitions of merge_origins static to match the java
Implemented render/render_to_sb methods for ConfigDelayedMerge

Fixed DefaultTransformer::transform method to actually compare the value type

Made SimpleConfigObject::indent static

SimpleConfigOrigin::merge_origins handles merging more than two tokens correctly

Implemented SimpleConfigOrigin#filename to use Chris's Url class

A couple methods in tokens.rb
  get_substitution_path_expression
  get_substitution_optional

Commented out some failing tests in conf_parser_spec until some missing functionality is implmented
```
* Merge pull request #31 from cprice404/feature/master/TK-160-port-conf-parser-tests (f28f78ea)


```
Merge pull request #31 from cprice404/feature/master/TK-160-port-conf-parser-tests

(TK-160) Initial scaffolding for conf parser tests
```
* (MAINT) add missing newline at end of file (ee375afb)

* (TK-160) Change `t` to `invalid` to match upstream (012dac77)

* (TK-160) Initial scaffolding for conf parser tests (04d56c9e)


```
(TK-160) Initial scaffolding for conf parser tests

This commit ports over the first few ConfParser tests, and fixes
a few bugs to get them passing.
```
* Merge pull request #29 from KevinCorcoran/with--vs-set (08ca846a)


```
Merge pull request #29 from KevinCorcoran/with--vs-set

(maint) rename methods to match upstream
```
* Merge pull request #30 from cprice404/maint/master/add-utf8-encoding-pragma (0f3ceb58)


```
Merge pull request #30 from cprice404/maint/master/add-utf8-encoding-pragma

(MAINT) Add utf-8 encoding pragma to all source files
```
* (MAINT) Add utf-8 encoding pragma to all source files (1e3b1a84)


```
(MAINT) Add utf-8 encoding pragma to all source files

Because ruby--
```
* (maint) rename methods to match upstream (7ed85816)


```
(maint) rename methods to match upstream

Rename methods whose names start with "set_" or "with_" to match
the names of these methods in the upstream Java project.
```
* Merge pull request #28 from KevinCorcoran/concatenation (212f6b7c)


```
Merge pull request #28 from KevinCorcoran/concatenation

(TK-162) implement concatenation and substitution
```
* (maint) fix bugs identified during PR review (d608f4a5)

* (TK-162) implement concatenation and substitution (bc71ba0f)


```
(TK-162) implement concatenation and substitution

Initial implementation of concatenation and substitution.  Ported the first test case
in ConcatenationTest and as much of the production code as it took to get it to pass.
```
* Merge pull request #27 from KevinCorcoran/add-test-util (65e3ab85)


```
Merge pull request #27 from KevinCorcoran/add-test-util

(maint) add TestUtils.parse_config
```
* (maint) add TestUtils.parse_config (1b47f6b4)

* Merge pull request #24 from jpinsonault/tk-169-setup-travis (6e5e8698)


```
Merge pull request #24 from jpinsonault/tk-169-setup-travis

(TK-169) Add travis support
```
* Updated Gemfile.lock (d8bd873e)

* Removed rake dependency and Rakefile, changed .travis.yml to run rspec instead of rake (9c36b479)

* Merge pull request #26 from jmccure/port-lossless-tokens (a7018fd9)


```
Merge pull request #26 from jmccure/port-lossless-tokens

Add lossless comment tokens
```
* Amend lossless token test name after feedback (9b94c6a9)

* Add lossless comment tokens (f14161f3)

* Merge pull request #22 from jpinsonault/tk-158-port-path-tests (005a8b6f)


```
Merge pull request #22 from jpinsonault/tk-158-port-path-tests

(TK-158) Port Path tests to ruby hocon
```
* Merge pull request #25 from KevinCorcoran/TK-128/fix-for-IP-addresses (1feaba32)


```
Merge pull request #25 from KevinCorcoran/TK-128/fix-for-IP-addresses

(TK-128) fix tokenization of unquoted strings
```
* Merge pull request #23 from KevinCorcoran/update-gemspec (c4da445a)


```
Merge pull request #23 from KevinCorcoran/update-gemspec

(maint) update gemspec with new URL and authors
```
* Changed command to use rake spec (5ae8b396)

* Addressed PR feedback (bd80a3ef)


```
Addressed PR feedback

Implemented Path#from_path_iterator as a constructor

Fixed typos

Implemented TokenIterator#to_list

Fleshed out BadPath exception message handling logic
```
* (TK-128) fix tokenization of unquoted strings (224c4dfd)


```
(TK-128) fix tokenization of unquoted strings

This commit fixes the tokenization of unquoted strings which might be
numbers.  In particular, this affects IP addresses.

The tokenizer aggressively attempts to parse such strings as
either a Float or Integer and relies on an error being raised to
indicate when the string is not actually a valid number.  However,
`to_i` and `to_f` never raise execptions, so the constructors must be
used instead.
```
* Changed script command (06fc855a)

* Changed rspec command (37d581cc)

* (TK-169) Add travis support (3fc140da)

* (maint) update gemspec with new URL and authors (d6561e42)

* (TK-159) Partial set of ConfigValue tests implemented (c4abaf2e)


```
(TK-159) Partial set of ConfigValue tests implemented
This is a partial set of the tests for ConfigValueTest.scala
We're going to get whatever functionality I've implemented in this PR so others can use it and
avoid creating merge conflicts.

The rest of the PRs will come as much smaller chunks of effort

This branch was rebased on top of Kevin's tk-162 PR, and hopefully I merged my changes into it without breaking the tests didn't catch.

Implemented parts of:
  ConfigDelayedMerge
  ConfigDelayedMergeObject
  ConfigReference
  ReplaceableMergeStack module

SimpleConfigList/Object now behave like arrays/hashes by delegating required functions to their @value attribute

Implemented ==() and hash() for a bunch of classes

Many other small changes
```
* Merge pull request #21 from jpinsonault/tk-157-port-token-tests (45414478)


```
Merge pull request #21 from jpinsonault/tk-157-port-token-tests

Tk 157 port token tests
```
* Moved shared examples into test_utils.rb and extracted out the random object examples (95a0db9b)

* Extracted shared examples into separate file for reuse in other tests (f9fe3386)

* (TK-158) Port Path tests to ruby hocon (bd832af6)

* Removed unused TestUtils method (8d7af9ec)

* (TK-157) Port Token tests to ruby hocon (921f9883)


```
(TK-157) Port Token tests to ruby hocon

Ported the Token tests
This involved implementing various == and hash functions for Token subclasses and Config types
```
* Merge pull request #20 from jpinsonault/tk-155-port-tokenizer-tests (5ebd16eb)


```
Merge pull request #20 from jpinsonault/tk-155-port-tokenizer-tests

(TK-155) Port tokenizer tests to ruby hocon
```
* Lots of fixes for PR (039d6f42)


```
Lots of fixes for PR

Used single quotes where appropriate
Extracted tokenize function
Changed TokenIterator.problem occurances to self.class.problem
```
* Implemented == method for token subtypes (e6a4b56b)

* (TK-155) Port tokenizer tests to ruby hocon (6a2e3f83)


```
(TK-155) Port tokenizer tests to ruby hocon

Ported all the java tests from the hocon library to ruby-hocon
Added a few more here and there

Implemented misc missing functions from the java library to get the tests passing

Fixed bug in tokenizer that ignored whitespace between tokens
```
* Update gemspec for 0.0.7 release (71f475fe)

* Merge pull request #18 from fpringvaldsen/json-patch (74e6ed8d)


```
Merge pull request #18 from fpringvaldsen/json-patch

Allow gem to parse JSON files
```
* Merge pull request #16 from fpringvaldsen/readme-disclaimer (df334bd8)


```
Merge pull request #16 from fpringvaldsen/readme-disclaimer

Add disclaimer to README
```
* Merge pull request #17 from fpringvaldsen/implement-end-token (b28b2909)


```
Merge pull request #17 from fpringvaldsen/implement-end-token

Fix NameError when parsing {\n}
```
* Allow gem to parse JSON files (b72cae0b)


```
Allow gem to parse JSON files

Allow the ruby hocon gem to parse JSON files. Previously,
attempting to parse a JSON file would lead to an uninitialized
constant error.
```
* Fix NameError when parsing {\n} (b1781fee)


```
Fix NameError when parsing {\n}

Fix a NameError that would occur when a string containing
{\n} was parsed.
```
* Add disclaimer to README (9f4b8df1)


```
Add disclaimer to README

Add a disclaimer to the README explaining that this library is in
an experimental state and some features may not work properly.
```
* Update gemspec for 0.0.6 release (1613e233)

* Merge pull request #15 from waynr/maint (b25f64f7)


```
Merge pull request #15 from waynr/maint

(MAINT) Fix spec tests such that they work on ruby-1.8.7-p352
```
* Fix unecessarily strict test case. (3ed91425)


```
Fix unecessarily strict test case.

As it turns out, hocon does not actually require that the output be
rendered in the same order by every implementation so when running with
ruby-1.9.x vs ruby-1.8.7-p352 for instance the rendered string may not have
variables specified in the same order.

However, hocon does require that comments be matched to their variables. This
patch validates that behavior by creating a hash of config-lines mapped to lists
of preceding comments and verifies that this hash is the same before and after
rendering regardless of which hocon implementation created the "original" output
file.

Also, I find the input vs output semantics and the way variables with these
names are used just a little confusing but whatever.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Remove unnecessary brackets in regex. (f0a72925)


```
Remove unnecessary brackets in regex.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Minor rspec testcase code cleanup. (a95cff41)


```
Minor rspec testcase code cleanup.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Fix re-parsed output test cases. (e5c4d884)


```
Fix re-parsed output test cases.

This testcase should not care about the rendered form of the re-parsed output
since A) the hocon spec does not guarantee exact output similarity and B)
testing that comments remain above the variables they describe is taken care of
in the previous test case.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Fix uninitialized constant error in ruby-1.8.7-p352 (53151934)


```
Fix uninitialized constant error in ruby-1.8.7-p352

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Fix tokenizer for ruby-1.8.7-p352 (00fe96e2)


```
Fix tokenizer for ruby-1.8.7-p352

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Fix default Rake task for ruby-1.8.7-p352 (f3bb2240)


```
Fix default Rake task for ruby-1.8.7-p352

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Merge pull request #13 from cprice404/maint/master/clean-up-requires (9868fd6f)


```
Merge pull request #13 from cprice404/maint/master/clean-up-requires

Clean up require statements
```
* Merge pull request #14 from fpringvaldsen/error-handling (8be042e6)


```
Merge pull request #14 from fpringvaldsen/error-handling

Improve Error Handling with invalid config
```
* Improve Error Handling with invalid config (64d6166f)


```
Improve Error Handling with invalid config

Implement Error Handling when an invalid config is parsed.
```
* Clean up require statements (f866d790)

### <a name = "0.0.5">0.0.5 - 1 Oct, 2014 (67d264f4)

* Update gemspec for 0.0.5 release (67d264f4)

* Merge pull request #12 from fpringvaldsen/add-methods-for-puppet (78c7afb9)


```
Merge pull request #12 from fpringvaldsen/add-methods-for-puppet

Add methods required for puppet .conf module
```
* Remove commented line (d704cda2)


```
Remove commented line

Delete commented constant in the Path class that was no longer
needed.
```
* Move requires into Hocon module (935b2cc5)


```
Move requires into Hocon module

Move requires for all files in the Hocon module into
the module itself to eliminate uninitialized constant errors.
```
* Fix ConfigImpl bug and add more tests (c892c0f4)


```
Fix ConfigImpl bug and add more tests

Fix bug in ConfigImpl wherein a boolean would be converted into
a ConfigBoolean with value true even if the boolean is false.
Increase test coverage for ConfigValueFactory tests by adding
a test to ensure this bug is no longer happening, and increase
test coverage of SimpleConfig spec tests by ensuring that
data structures can be added to a config.
```
* Add without_path method (d23fdcde)


```
Add without_path method

Port without_path method from the Java HOCON library into the
SimpleConfig class.
```
* Add at_key and at_path methods (8323c2a6)


```
Add at_key and at_path methods

Port the at_key and at_path methods from the Java HOCON library
into the AbstractConfigValue class.
```
* Add "add" method to TokenWithComments (3430c3b7)


```
Add "add" method to TokenWithComments

Port the "add" method to the TokenWithComments class.
```
* Fix requires in ConfigValueFactory (a4074d71)


```
Fix requires in ConfigValueFactory

Fix the require statements so that ConfigValueFactory can be
required without requiring other files.
```
* Add ConfigValueFactory (ae88610e)


```
Add ConfigValueFactory

This commit adds a basic implementation of the ConfigValueFactory
class. This class contains only one method, with_any_ref, which
takes an object and transforms it into a ConfigObject.
```
* Add with_value method to SimpleConfig (760f7743)


```
Add with_value method to SimpleConfig

Port the with_value method in the SimpleConfig class from
the Java HOCON library.
```
* Add has_path method (655c1beb)


```
Add has_path method

Port the has_path method in the SimpleConfig class from the
Java HOCON library.
```
* Put get_value tests into their own file (9339f606)


```
Put get_value tests into their own file

Move the tests of the SimpleConfig get_value method into a new
file, simple_config_spec.rb
```
* Add get_value method to SimpleConfig (bfb63a35)


```
Add get_value method to SimpleConfig

Add the get_value method to SimpleConfig, which allows the user
to get a value from a configuration file. Add tests for this
method.
```
* Merge pull request #8 from dakatsuka/add-bundler-and-rake (d204b344)


```
Merge pull request #8 from dakatsuka/add-bundler-and-rake

Add bundler and rake
```
* Merge pull request #9 from dakatsuka/support-boolean (f584904f)


```
Merge pull request #9 from dakatsuka/support-boolean

Support boolean
```
* Add tests for Hocon::Impl::ConfigBoolean (31fd73b6)

* Implement Hocon::Impl::ConfigBoolean (927d64b7)

* Add bundler and rake (c0f77be8)

### <a name = "0.0.3">0.0.3 - 24 Jul, 2014 (6cd552c3)

* Merge pull request #6 from waynr/maint (6cd552c3)


```
Merge pull request #6 from waynr/maint

Maint
```
* spec_helper: Fix EXAMPLE1 w/ empty list. (775098d9)


```
spec_helper: Fix EXAMPLE1 w/ empty list.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Hocon: Fix spec tests by adding `load` and `parse` (702146cc)


```
Hocon: Fix spec tests by adding `load` and `parse`

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* spec: Add spec tests or Hocon module. (5b65bbef)


```
spec: Add spec tests or Hocon module.

The goal here is to provide an interface similar to what the JSON ruby module
provides, even though this doesn't include a dump method yet.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* hocon.gemspec: Update gemspec for new gem release. (95d46911)


```
hocon.gemspec: Update gemspec for new gem release.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* parser: Don't convert anything to symbols. (0ca29caf)


```
parser: Don't convert anything to symbols.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Fix Hocon::Impl::SimpleConfigList (3f77504f)


```
Fix Hocon::Impl::SimpleConfigList

Chokes without this `new_copy` method.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* spec: Add new examples, reorganize specs. (4a9cfb1b)


```
spec: Add new examples, reorganize specs.

Reorganize specs to allow for the addition of more examples.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Merge pull request #5 from waynr/fix-settings-in-hocon-gemspec (14e4ed32)


```
Merge pull request #5 from waynr/fix-settings-in-hocon-gemspec

gemspec: Fix settings in hocon.gemspec.
```
* Merge pull request #3 from jmccure/fix_issue_2 (38fdfc37)


```
Merge pull request #3 from jmccure/fix_issue_2

Fixed error when conf file had empty array. Issue #2
```
* Merge pull request #4 from waynr/implement-hocon-configfactory-parsestring (464d5704)


```
Merge pull request #4 from waynr/implement-hocon-configfactory-parsestring

Implement hocon configfactory parsestring
```
* Fixed error when conf file had empty array. Issue #2 (fb1248eb)

### <a name = "0.0.2">0.0.2 - 24 Jul, 2014 (95dffaea)

* gemspec: Fix settings in hocon.gemspec. (95dffaea)


```
gemspec: Fix settings in hocon.gemspec.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Implement Hocon.ConfigFactory.parse_string (430442e4)


```
Implement Hocon.ConfigFactory.parse_string

Also fixes a number of typos an previously untested code paths.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* spec: Add Hocon::ConfigFactory.parse_string test. (1cec69f2)


```
spec: Add Hocon::ConfigFactory.parse_string test.

Signed-off-by: Wayne <wayne@puppetlabs.com>
```
* Update README.md (9ce283b1)

### <a name = "0.0.1">0.0.1 - 16 Mar, 2014 (f7dbca52)

* Initial release.
