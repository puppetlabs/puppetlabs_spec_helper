# DEVELOPMENT NOTES

## Building the Gem
To build the gem just run `rake build`
If you need to compare the gemspec file built into the gem just run:
`bundle exec rake build && gem specification pkg/puppetlabs_spec_helper-1.2.0.gem --ruby`

## Version file
As part of the `rake build` task, the gemspec will reference the version that is
defined in the `lib/puppetlabs_spec_helper/version.rb` file.  

## Releasing
To release the gem just run the following things.

### 1. Update the version
update the version file : `lib/puppetlabs_spec_helper/version.rb`

```ruby
module PuppetlabsSpecHelper
  module Version
    STRING = '1.0.1'
  end
end
```

### 2. Generate and push the release to git
rake git:release

### 3. Tag and release to git
Since the default behavior of bundler is to use tags like `v1.0.1` we cannot use
the `git:release` task and will need to use `git:pl_release` which creates a tag
without the `v` and pushes to master.

### 4. Release to rubygems
rake release
