# DEVELOPMENT NOTES

## Building Gemspec

To keep the gem accessible to people running older rubies, the gemspec may only contain dependencies on gems that are available to all supported rubies. Features that need gems compatible only to some versions of ruby need to be coded in a way that is optional, and specify their gem dependencies in the Gemfile, conditional on the ruby version. Add a note to the README about those.

## Releasing
To release the gem run the following things.

### 1. Update the version
update the version file: `lib/puppetlabs_spec_helper/version.rb`

### 2. Release the gem
    rake release[remote]
