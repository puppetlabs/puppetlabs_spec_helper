# DEVELOPMENT NOTES

## Building Gemspec
The Rakefile includes all the info that the gemspec file will contain. You have to update
the Rakefile instead of the gemspec.
To regenerate the gemspec just run `rake gemspec` and a new gemspec will be created
with everything required.

Running `rake build` will build out the gemspec according to the Rakefile parameters.

```ruby
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "puppetlabs_spec_helper"
  gem.version = "#{PuppetlabsSpecHelper::Version::STRING}"
  gem.homepage = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  gem.license = "Apache-2.0"
  gem.summary = %Q{Standard tasks and configuration for module spec tests}
  gem.description = %Q{Contains rake tasks and a standard spec_helper for running spec tests on puppet modules}
  gem.email = ["modules-dept@puppetlabs.com"]
  gem.authors = ["Puppet Labs"]
  # dependencies defined in Gemfile
end

```

## Version file
As part of the `rake gemspec` task, the gemspec will reference the version that is
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
rake gemspec:release

### 3. Tag and release to git
Since the default behavior of jewler is to use tags like `v1.0.1` we cannot use
the `git:release` task and will need to use `git:pl_release` which creates a tag
without the `v` and pushes to master.

### 4. Release to rubygems
rake release
