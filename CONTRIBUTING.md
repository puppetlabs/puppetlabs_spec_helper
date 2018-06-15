# DEVELOPMENT NOTES

## Building Gemspec

To keep the gem accessible to people running older rubies, the gemspec may only contain dependencies on gems that are available to all supported rubies. Features that need gems compatible only to some versions of ruby need to be coded in a way that is optional, and specify their gem dependencies in the Gemfile, conditional on the ruby version. Add a note to the README about those.

[`Gemfile.lock`](https://stackoverflow.com/a/7518215/844449) file is used to pin resolved gem versions to achieve reproducible builds. If you like to change some gem dependencies, change them in Gemfile and invoke `bundle`. If you like to update dependencies to newer versions, update the lock with `bundle update` or `bundle update <gem>`. Commit the lock file after either. Remember to commit `Gemfile.lock` with default settings for this repository, that is:

 * Ruby 2.1
 * Puppet ~> 4

Example:

```bash
# make some Gemfile changes
rvm use 2.1
unset PUPPET_GEM_VERSION PUPPET_VERSION
bundle
git commit -a
```

or explicitly updating dependencies to newer versions:

```bash
rvm use 2.1
unset PUPPET_GEM_VERSION PUPPET_VERSION
bundle update
git commit -a
```

## Releasing
To release the gem run the following things.

### 1. Update the version
update the version file: `lib/puppetlabs_spec_helper/version.rb`

### 2. Release the gem
    rake release[remote]
