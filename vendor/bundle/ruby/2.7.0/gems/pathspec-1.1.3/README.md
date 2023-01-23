# pathspec-ruby

[![Gem Version](https://badge.fury.io/rb/pathspec.svg)](https://badge.fury.io/rb/pathspec) [![Ruby](https://github.com/highb/pathspec-ruby/actions/workflows/ruby.yml/badge.svg)](https://github.com/highb/pathspec-ruby/actions/workflows/ruby.yml) [![Maintainability](https://api.codeclimate.com/v1/badges/4f3b5917e01fb34f790d/maintainability)](https://codeclimate.com/github/highb/pathspec-ruby/maintainability) [![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=highb_pathspec-ruby&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=highb_pathspec-ruby)

[man Page as HTML](http://highb.github.io/pathspec-ruby/)

[Supported Rubies](https://www.ruby-lang.org/en/downloads/):

- 2.6 (Security Maintenance)
- 2.7 (Stable, Tested)
- 3.0 (Stable, Tested)

Match Path Specifications, such as .gitignore, in Ruby!

Follows .gitignore syntax defined on [gitscm](http://git-scm.com/docs/gitignore)

.gitignore functionality ported from [Python pathspec](https://pypi.python.org/pypi/pathspec/0.2.2) by [@cpburnz](https://github.com/cpburnz/python-path-specification)

## Build/Install from Rubygems

```shell
gem install pathspec
```

## CLI Usage

```bash
➜ cat .gitignore
*.swp
/coverage/
➜ bundle exec pathspec-rb specs_match "coverage/foo"
/coverage/
➜ bundle exec pathspec-rb specs_match "file.swp"
*.swp
➜ bundle exec pathspec-rb match "file.swp"
➜ echo $?
0
➜ ls
Gemfile      Gemfile.lock coverage     file.swp     source.rb
➜ bundle exec pathspec-rb tree .
./coverage
./coverage/index.html
./file.swp
```

## Usage

```ruby
require 'pathspec'

# Create a .gitignore-style Pathspec by giving it newline separated gitignore
# lines, an array of gitignore lines, or any other enumable object that will
# give strings matching the .gitignore-style (File, etc.)
gitignore = PathSpec.from_filename('spec/files/gitignore_readme')

# Our .gitignore in this example contains:
# !**/important.txt
# abc/**

# true, matches "abc/**"
gitignore.match 'abc/def.rb'
# CLI equivalent: pathspec.rb -f spec/files/gitignore_readme match 'abc/def.rb'

# false, because it has been negated using the line "!**/important.txt"
gitignore.match 'abc/important.txt'
# CLI equivalent: pathspec.rb -f spec/files/gitignore_readme match 'abc/important.txt'

# Give a path somewhere in the filesystem, and the Pathspec will return all
# matching files underneath.
# Returns ['/src/repo/abc/', '/src/repo/abc/123']
gitignore.match_tree '/src/repo'
# CLI equivalent: pathspec.rb -f spec/files/gitignore_readme tree /src/repo

# Give an enumerable of paths, and Pathspec will return the ones that match.
# Returns ['/abc/123', '/abc/']
gitignore.match_paths ['/abc/123', '/abc/important.txt', '/abc/']
# There is no CLI equivalent to this.
```

## Example Usage in Gemspec

```
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gemspec_pathspec_test/version"
require 'pathspec'

Gem::Specification.new do |spec|
  spec.name          = "gemspec_pathspec_test"
  spec.version       = GemspecPathspecTest::VERSION
  spec.authors       = ["Brandon High"]
  spec.email         = ["highb@users.noreply.github.com"]

  spec.summary = "whatever"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  ps = PathSpec.from_filename('.gitignore')
  spec.files         = Dir['lib/*.rb'].reject { |f| ps.match(f) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
```

## Building/Installing from Source

```shell
git clone git@github.com:highb/pathspec-ruby.git
cd pathspec-ruby && bash ./build_from_source.sh
```

## Contributing

Pull requests, bug reports, and feature requests welcome! :smile: I've tried to write exhaustive tests but who knows what cases I've missed.

## Releasing

This is mainly a reminder to myself but the release process is:
1. Make sure CI is passing
2. Update the CHANGELOG with relevant changes to Gem consumers
3. Update version in gemspec with correct SemVer bump for scope of changes
4. Tag/release using GitHub UI and the Build & Push workflow should do the rest.
