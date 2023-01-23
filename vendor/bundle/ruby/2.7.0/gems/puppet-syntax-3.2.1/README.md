# puppet-syntax

[![License](https://img.shields.io/github/license/voxpupuli/puppet-syntax.svg)](https://github.com/voxpupuli/puppet-syntax/blob/master/LICENSE.txt)
[![Release](https://github.com/voxpupuli/puppet-syntax/actions/workflows/syntax.yml/badge.svg)](https://github.com/voxpupuli/puppet-syntax/actions/workflows/syntax.yml)
[![RubyGem Version](https://img.shields.io/gem/v/puppet-syntax.svg)](https://rubygems.org/gems/puppet-syntax)
[![RubyGem Downloads](https://img.shields.io/gem/dt/puppet-syntax.svg)](https://rubygems.org/gems/puppet-syntax)

# Puppet::Syntax

Puppet::Syntax checks for correct syntax in Puppet manifests, templates, and
Hiera YAML.

## Version support

Puppet::Syntax is supported with:

- Puppet >= 5.0 that provides the `validate` face.
- Ruby >= 2.4

For the specific versions that we test against, see the [GitHub Actions workflow](.github/workflows/test.yml).

## Installation

To install Puppet::Syntax, either add it to your module's Gemfile or install
the gem manually.

* To install with the Gemfile, add:

```ruby
gem 'puppet-syntax'
```

  And then execute:

```sh
bundle install
```

* To install the gem yourself, run:

```sh
gem install puppet-syntax
```

## Configuration

To configure Puppet::Syntax, add any of the following settings to your `Rakefile`.

* To exclude certain paths from the syntax checks, set:

```ruby
PuppetSyntax.exclude_paths = ["vendor/**/*"]
```

* To configure specific paths for the Hiera syntax check, specify `hieradata_paths`. This is useful if you use Hiera data inside your module.

```ruby
PuppetSyntax.hieradata_paths = ["**/data/**/*.yaml", "hieradata/**/*.yaml", "hiera*.yaml"]
```

* To configure specific paths for the Puppet syntax checks or for the templates checks, specify `manifests_paths` or `templates_paths` respectively. This is useful if you want to check specific paths only.

```ruby
PuppetSyntax.manifests_paths = ["**/environments/future/*.pp"]
PuppetSyntax.templates_paths = ["**/modules/**/templates/*.erb"]
```

* To ignore deprecation warnings, disable `fail_on_deprecation_notices`. By default, `puppet-syntax` fails if it encounters Puppet deprecation notices. If you are working with a legacy code base and want to ignore such non-fatal warnings, you might want to override the default behavior.

```ruby
PuppetSyntax.fail_on_deprecation_notices = false
```

* To enable a syntax check on Hiera keys, set:

```ruby
PuppetSyntax.check_hiera_keys = true
```

This reports common mistakes in key names in Hiera files, such as:

* Leading `::` in keys, such as: `::notsotypical::warning2: true`.
* Single colon scope separators, such as: `:picky::warning5: true`.
* Invalid camel casing, such as: `noCamelCase::warning3: true`.
* Use of hyphens, such as: `no-hyphens::warning4: true`.

## Usage

* To enable Puppet::Syntax, include the following in your module's `Rakefile`:

```ruby
require 'puppet-syntax/tasks/puppet-syntax'
```

For Continuous Integration, use Puppet::Syntax in conjunction with `puppet-lint`
and spec tests. Add the following to your module's `Rakefile`:

```ruby
task :test => [
  :syntax,
  :lint,
  :spec,
]
```

* To test all manifests and templates, relative to the location of the `Rakefile`, run:

```
$ bundle exec rake syntax
---> syntax:manifests
---> syntax:templates
---> syntax:hiera:yaml
```

* To return a non-zero exit code and an error message on any failures, run:

```
$ bundle exec rake syntax
---> syntax:manifests
rake aborted!
Could not parse for environment production: Syntax error at end of file at demo.pp:2
Tasks: TOP => syntax => syntax:manifests
(See full trace by running task with --trace)
```

## Checks

Puppet::Syntax makes the following checks in the directories and subdirectories
of the module, relative to the location of the `Rakefile`.

### Hiera

Checks `.yaml` files for syntax errors.

By default, this rake task looks for all `.yaml` files in a single module under:

* `**/data/**/*.yaml`
* `hieradata/**/*.yaml`
* `hiera*.yaml`

### manifests

Checks all `.pp` files in the module for syntax errors.

### templates

#### erb

Checks `.erb` files in the module for syntax errors.

#### epp

Checks `.epp` files in the module for syntax errors.

EPP checks are supported in Puppet 4 or greater, or in Puppet 3 with the future
parser enabled.

## Contributing

1. Fork the repo.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create new Pull Request.

## Making a new Release

* Update version in `lib/puppet-syntax/version.rb`
* Run the changelog rake task (bundle exec rake changelog)
* Create a PR
* Get it reviewed and merged
* update the local repo, create a signed git tag, prefixed with a v, matching the new version (git tag -s v1.2.3)
* GitHub action will publish to GitHub Packages and Rubygems
