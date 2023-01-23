# pathspec-ruby CHANGELOG

## 1.1.0 (Minor Release)

- (Maint) Updated Supported Ruby Versions
- (Maint) Linting corrections

## Undocumented Releases (Sorry!)

## 0.2.0 (Minor Release)
- (Feature) A CLI tool, pathspec-rb, is now provided with the gem.
- (API Change) New namespace for gem: `PathSpec`: Everything is now namespaced under `PathSpec`, to prevent naming collisions with other libraries. Thanks @tenderlove!
- (License) License version updated to Apache 2. Thanks @kytrinyx!
- (Maint) Pruned Supported Ruby Versions. We now test: 2.2.9, 2.3.6 and 2.4.3.
- (Maint) Ruby 2.5.0 testing is blocked on Travis, but should work locally. Thanks @SumLare!
- (Maint) Added Rubocop and made some corrections

## 0.1.2 (Patch/Bug Fix Release)
- Fix for regexp matching Thanks @incase! #16
- File handling cleanup Thanks @martinandert! #13
- `from_filename` actually works now! Thanks @martinandert! #12

## 0.1.0 (Minor Release)
- Port new edgecase handling from [python-path-specification](https://github.com/cpburnz/python-path-specification/pull/8). Many thanks to @jdpace! :)
- Removed EOL Ruby support
- Added current Ruby stable to Travis testing

## 0.0.2 (Patch/Bug Fix Release)
- Fixed issues with Ruby 1.8.7/2.1.1
- Added more testing scripts
- Fixed Windows path related issues
- Cleanup unnecessary things in gem

## 0.0.1
- Initial version.
