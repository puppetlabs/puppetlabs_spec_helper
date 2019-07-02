Puppet Labs Spec Helper
=======================

The Short Version
-----------------

This repository is meant to provide a single source of truth for how to
initialize different Puppet versions for spec testing.

The common use case is a module such as
[stdlib](http://forge.puppetlabs.com/puppetlabs/stdlib) that works with many
versions of Puppet.  The stdlib module should require the spec helper in this
repository, which will in turn automatically figure out the version of Puppet
being tested against and perform version specific initialization.

Other "customers" that should use this module are:

 * [Facter](https://github.com/puppetlabs/facter)
 * [PuppetDB](https://github.com/puppetlabs/puppetdb)
 * [Mount Providers](https://github.com/puppetlabs/puppetlabs-mount_providers)

Usage
=====

When developing or testing modules, simply clone this repository and install the
gem it contains. The recommended way to do this is using [bundler](http://bundler.io/#getting-started).

Example Gemfile:

    source 'https://rubygems.org'
    gem 'puppetlabs_spec_helper'

Add this to your project's spec\_helper.rb:

    require 'puppetlabs_spec_helper/module_spec_helper'

Add this to your project's Rakefile:

    require 'puppetlabs_spec_helper/rake_tasks'

And run the spec tests:

    $ cd $modulename
    $ rake spec


### Parallel Fixture Downloads
Fixture downloads will now execute in parallel to speed up the testing process. Which can represent >= 600% speed increase (depending on number of threads). You can control the amount of threads by setting the `MAX_FIXTURE_THREAD_COUNT` environment variable
to a positive integer, the default is currently 10.  We don't suggest going higher than 25 as the gains are marginal due to some repos taking a long time to download.  Please be aware that your internal VCS system may not be able to handle a high load in which case the server would fail to clone the repository. Because of this issue, this setting is tunable via `MAX_FIXTURE_THREAD_COUNT`.

Additionally, you can also speed up cloning when using the ssh protocol by multiplexing ssh sessions.  Add something similar to your ssh config.
Note: you may need to change the host if your using an internal git server.

```shell
Host github.com
  ControlMaster auto
  ControlPath ~/.ssh/ssh-%r@%h:%p
  ControlPersist yes

```

Note: parallel downloads is only available for repositories and not forge modules.

### Parallel tests
It is also possible to use the `parallel_tests` Gem via the `:parallel_spec` Rake task to run rspec commands in parallel on groups of spec files.

Use of parallelization at this level can result in large performance benefits when the Rspec examples tend to cause a number of large, CPU-intensive catalog compilations to occur.  An example of where this might be the case is in a complex module with a lot of tests or a control repo with many hosts.

Be aware however that in other circumstances this parallelization can result in the tests actually taking longer to run.  The best thing to do is time `rspec spec` and `rspec parallel_spec` and use the parallelization only when there is a clear benefit.

To enable this feature, add the `parallel_tests` Gem to your project's Gemfile:

    gem 'parallel_tests'

And then to run spec tests in parallel:

    $ rake parallel_spec

Issues
======

Please file issues against this project at the [Puppet Labs Issue Tracker](https://tickets.puppetlabs.com/browse/MODULES)

The Long Version
----------------

Purpose of this Project
=======================

This project is intended to serve two purposes:

1. To serve as a bridge between external projects and multiple versions of puppet;
   in other words, if your project has a dependency on puppet, you shouldn't need
   to need to worry about the details of how to initialize puppet's state for
   testing, no matter what version of puppet you are testing against.
2. To provide some convenience classes / methods for doing things like creating
   tempfiles, common rspec matchers, etc.  These classes are in the puppetlabs\_spec
   directory.
3. To provide a common set of Rake tasks so that the procedure for testing modules
   is unified.

To Use this Project
===================

The most common usage scenario is that you will check out the 'master'
branch of this project from github, and install it as a rubygem.
There should be few or no cases where you would want to have any other
branch of this project besides master/HEAD.

Running on non-current ruby versions
------------------------------------

Since gem and bundler, ruby's package management tools, do not take the target ruby version into account when downloading packages, the puppetlabs_spec_helper gem can only depend on gems that are available for all supported ruby versions. If you can/want to use features from other packages, install those additional packages manually, or have a look at the Gemfile, which provides code to specify those dependencies in a more "friendly" way. This currently affects the following gems:

* puppet
* rubocop
* rubocop-rspec
* json_pure
* rack

Initializing Puppet for Testing
===============================

In most cases, your project should be able to define a spec\_helper.rb that includes
just this one simple line:

    require 'puppetlabs_spec_helper/puppet_spec_helper'

Then, as long as the gem is installed, you should be all set.

If you are using rspec-puppet for module testing, you will want to include a different
library:

    require 'puppetlabs_spec_helper/module_spec_helper'

NOTE that this is specifically for initializing Puppet's core.  If your project does
not have any dependencies on puppet and you just want to use the utility classes,
see the next section.

A number of the Puppet parser features, controlled via configuration during a
normal puppet run, can be controlled by exporting specific environment
variables for the spec run. These are:

* ``STRICT_VARIABLES`` - set to "yes" to enable set to strict variable checking when using Puppet versions between 3.5 and 4.0;
  set to "no" to disable strict variable checking on Puppet versions 4.0, and later.
  See [strict_variables](http://docs.puppetlabs.com/references/latest/configuration.html#strictvariables)
  in puppet.conf for details.
* ``ORDERING`` - set to the desired ordering method ("title-hash", "manifest", or "random")
  to set the order of unrelated resources when applying a catalog. Leave unset for the default
  behavior, currently "random". This is equivalent to setting [ordering](http://docs.puppetlabs.com/references/latest/configuration.html#ordering)
  in puppet.conf.
* The following options only affect Puppet 3.x:
  * ``FUTURE_PARSER`` _(Puppet 3.x, starting with 3.2)_ - set to "yes" to enable the [future parser](https://docs.puppet.com/puppet/3/experiments_future.html),
    the equivalent of setting [parser=future](https://puppet.com/docs/puppet/3.8/configuration.html#parser)
    in puppet.conf.
  * ``TRUSTED_NODE_DATA``  _(Puppet 3.x, starting with 3.4)_ - set to "yes" to enable [the $facts hash and trusted node data](https://puppet.com/docs/puppet/3.8/lang_facts_and_builtin_vars.html#trusted-facts),
    which enabled ``$facts`` and ``$trusted`` hashes. This is equivalent to setting
    [trusted_node_data=true](https://puppet.com/docs/puppet/3.8/configuration.html#trustednodedata)
    in puppet.conf.    
  * ``STRINGIFY_FACTS``  _(Puppet 3.x, starting with 3.5)_  - set to "no" to enable [structured facts](http://docs.puppetlabs.com/facter/2.0/fact_overview.html#writing-structured-facts),
    otherwise leave unset to retain the current default behavior. This is equivalent to setting
    [stringify_facts=false](https://puppet.com/docs/puppet/3.8/configuration.html#stringifyfacts)
    in puppet.conf.

As an example, to run spec tests with the future parser, strict variable checking,
and manifest ordering, you would:

    FUTURE_PARSER=yes STRICT_VARIABLES=yes ORDERING=manifest rake spec


Using Utility Classes
=====================
If you'd like to use the Utility classes (PuppetlabsSpec::Files,
PuppetlabsSpec::Fixtures), you just need to add this to your project's spec\_helper.rb:

    require 'puppetlabs_spec_helper/puppetlabs_spec_helper'

NOTE that the above line happens automatically if you've required
'puppetlabs\_spec\_helper/puppet\_spec\_helper', so you don't need to do both.

In either case, you'll have all of the functionality of Puppetlabs::Files,
Puppetlabs::Fixtures, etc., mixed-in to your rspec context.

Using Fixtures
==============
`puppetlabs_spec_helper` has the ability to populate the
`spec/fixtures/modules` directory with dependent modules when `rake spec` or
`rake spec_prep` is run. To do so, all required modules should be listed in a
file named `.fixtures.yml` in the root of the project. You can specify a alternate location for that file in the `FIXTURES_YML` environment variable.

You can use the `MODULE_WORKING_DIR` environment variable to specify a diffent location when installing module fixtures via the forge. By default the
working directory is `<module directory>/spec/fixtures/work-dir`.

*Puppet Labs Spec Helper* supports installting modules from:

 * SCM repositories via `repositories` key,
 * Forge repositories via `forge_modules` key,
 * Forge repositories from dependencies defined in `metadata.json` via `metadata` key.

For more details on how to use those setting see [examples](#fixtures-examples).

When specifying the repo source of the fixture you have a few options as to which revision of the codebase you wish to use, and optionally, the puppet versions where the fixture is needed.

 * `repo` - the url to the repo
 * `scm` - options include git or hg. This is an optional step as the helper code will figure out which scm is used.

   ```yaml
   scm: git
   scm: hg
   ```

 * `target` - the directory name to clone the repo into ie. `target: mymodule`  defaults to the repo name  (Optional)
 * `subdir` - directory to be removed from the cloned repo. Its contents will be moved to the root directory (Optional)
 * `ref` - used to specify the tag name like version hash of commit (Optional)

   ```yaml
   ref: 1.0.0
   ref: 880fca52c
   ```
 * `branch` - used to specify the branch name you want to use ie. `branch: development`
 * `flags` - additional flags passed to the module installer (both puppet and scm)

   ```yaml
   flags: --verbose
   ```
 * `puppet_version` - versions of puppet for which the fixture should be installed. Ruby version constraints are supported. Only works when the `semantic_puppet` gem is available (shipped with puppet 4.0 and up, by default).

   ```yaml
   puppet_version: '>= 6.0.0'
   ```

 **Notes:**

 * `ref` and `branch` can be used together to get a specific revision on a specific branch
 * Top level `defaults` option could be used to set global options

Fixtures Examples
-----------------
Basic fixtures that will symlink `spec/fixtures/modules/my_modules` to the
project root:

```yaml
fixtures:
  symlinks:
    my_module: "#{source_dir}"
```

This is the same as specifying no symlinks fixtures at all.

Add `firewall` and `stdlib` as required module fixtures:

```yaml
fixtures:
  repositories:
    firewall: "git://github.com/puppetlabs/puppetlabs-firewall"
    stdlib: "git://github.com/puppetlabs/puppetlabs-stdlib"
```

Put a supplementary repository at a different location

```yaml
fixtures:
  repositories:
    firewall: "git://github.com/puppetlabs/puppetlabs-firewall"
    stdlib: "git://github.com/puppetlabs/puppetlabs-stdlib"
    control_repo:
      repo: "https://github.com/puppetlabs/control-repo"
      target: "spec/fixtures/control_repos"
```

Specify that the git tag `2.4.2` of `stdlib` should be checked out:

```yaml
fixtures:
  repositories:
    firewall: "git://github.com/puppetlabs/puppetlabs-firewall"
    stdlib:
      repo: "git://github.com/puppetlabs/puppetlabs-stdlib"
      ref: "2.6.0"
```

Only install the `yumrepo_core` module when testing against Puppet 6 or greater:

```yaml
fixtures:
  repositories:
    yumrepo_core:
      repo: "git://github.com/puppetlabs/puppetlabs-yumrepo_core"
      puppet_version: ">= 6.0.0"
```

Move manifests and siblings to root directory when they are inside a `code` directory:

```yaml
fixtures:
  repositories:
    stdlib:
      repo: "git://github.com/puppetlabs/puppetlabs-extradirectory"
      subdir: "code"
```

Install modules from Puppet Forge:

```yaml
fixtures:
  forge_modules:
    firewall: "puppetlabs/firewall"
    stdlib:
      repo: "puppetlabs/stdlib"
      ref: "2.6.0"
```

Install modules based on dependencies from `metadata.json`:

```yaml
fixtures:
  metadata:
    autoinstall_dependencies: true
    forge: https://puppetforge.acmecorp.lan # optional
```

Pass additional flags to module installation:

```yaml
fixtures:
  forge_modules:
    stdlib:
      repo: "puppetlabs/stdlib"
      ref: "2.6.0"
      flags: "--module_repository https://puppetforge.acmecorp.lan"
  repositories:
    firewall:
      repo: "git://github.com/puppetlabs/puppetlabs-firewall"
      ref: "2.6.0"
      flags: "--verbose"
```

Use `defaults` to define global parameters:

```yaml
defaults:
  forge_modules:
    flags: "--module_repository https://puppetforge.acmecorp.lan"
fixtures:
  forge_modules:
    stdlib:
      repo: "puppetlabs/stdlib"
      ref: "2.6.0"
  repositories:
    firewall:
      repo: "git://github.com/puppetlabs/puppetlabs-firewall"
      ref: "2.6.0"
```

Testing Parser Functions
========================

This whole section is superseded by improved support of accessing the scope in
rspec-puppet.


Modify rspec behavior
================================

#### Running Rspec with additional settings

You can add command line options to rspec using the `CI_SPEC_OPTIONS` environment variable.  Any text in the `CI_SPEC_OPTIONS` environment variable is added as an rspec option.  For example:

If you wanted to output JUnit test reports for a Jenkins CI server you could use;

Bash
``` bash
export CI_SPEC_OPTIONS = "-r yarjuf -f JUnit -o result.xml"
```

PowerShell
``` bash
$ENV:CI_SPEC_OPTIONS = '-r yarjuf -f JUnit -o result.xml'
```

And then run
```
bundle exec rake spec
```

This would cause rspec to load the `yarjuf` gem and output the results in JUnit format to the file `result.xml`

#### Running specs in parallel
When executing tests in a matrix CI environment, tests can be split up to run
a share of specs per CI node in parallel.  Set the ``CI_NODE_TOTAL`` environment
variable to the total number of nodes, and the ``CI_NODE_INDEX`` to a number
between 1 and the ``CI_NODE_TOTAL``.

If using Travis CI, add new lines to the "env" section of .travis.yml per node,
remembering to duplicate any existing environment variables:

    env:
      - FUTURE_PARSER=yes CI_NODE_TOTAL=2 CI_NODE_INDEX=1
      - FUTURE_PARSER=yes CI_NODE_TOTAL=2 CI_NODE_INDEX=2

#### Running tests tagged with test tiers
To run tests tagged with risk levels set the ``TEST_TIERS`` environment variable to a comma-separated list of the appropriate tiers.

For example: to run tests marked ``tier_high => true`` and ``tier_medium => true`` in the same test run set the
environment variable``TEST_TIERS=high,medium``

By default ``TEST_TIERS`` only accepts low, medium and high as valid tiers.  If you would like to use your own keywords to set the environment variable ``TEST_TIERS_ALLOWED``.

For example: to use the keywords dev, rnd, staging and production you can set
``TEST_TIERS_ALLOWED=dev,rnd,staging,production``. Then you would be able to run tests marked ``tier_dev => true``, ``tier_production => true`` with ``TEST_TIERS=dev,production``

Note, if the ``TEST_TIERS`` environment variable is set to empty string or nil, all tiers will be executed.


Generating code coverage reports
================================

This section describes how to add code coverage reports for Ruby files (types, providers, ...).
See the documentation of [RSpec-Puppet](https://github.com/rodjek/rspec-puppet)
for Puppet manifest coverage reports.

Starting with Ruby 1.9, the *de facto* standard for Ruby code coverage is
[SimpleCov](https://github.com/colszowka/simplecov). It is implemented as a Rake task in this gem.

To run code coverage:

    $ rake spec:simplecov

Reports are written to `/coverage/`, which you should add to `.gitignore`.

The reports can be generated every time you invoke RSpec, e.g. via `rake spec`,
You can enable it, set the following environment variable:s

``SIMPLECOV=yes``

Remember to add the simplecov-console and codecov gems to your `Gemfile`.

Using Coveralls
---------------

You can also use [Coveralls](https://coveralls.io/) together with SimpleCov:

```Ruby
# First line of spec/spec_helper.rb
require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter '/spec/'
  # Exclude bundled Gems in `/.vendor/`
  add_filter '/.vendor/'
end

require 'puppetlabs_spec_helper/module_spec_helper'
# Further content
```

Remember to add `gem 'coveralls', require: false` to your `Gemfile`.

Some Notes for Windows Users
============================

A windows users may need to do one of two things to execute `rake spec`.

Although things may appear to work, the init.pp may not transfer to the fixtures folder as needed
or may transfer as an empty file.

This is related to a registry security setting requiring elevated privileges to create symbolic links.

Currently, there are two known approaches to get around this problem.

- run your windows shell (cmd) as an Administrator
or
- modify the registry entry settings to allow symbolic links to be created.

The following links may give you some insight into why...

[Server Fault Post](http://serverfault.com/questions/582944/puppet-file-link-doesnt-create-target-under-windows)

[Stack Overflow Post](http://stackoverflow.com/questions/229643/how-do-i-overcome-the-the-symbolic-link-cannot-be-followed-because-its-type-is)

[Microsoft TechNet](https://technet.microsoft.com/en-us/library/cc754077.aspx)

mock_with
=========

There are two major mocking frameworks in modules test suites today: [mocha](https://rubygems.org/gems/mocha) and [rspec-mocks](https://rubygems.org/gems/rspec-mocks). We recommend that you choose rspec-mocks explicitly by specifying `mock_with`, either in your `spec_helper.rb` like so:

```
RSpec.configure do |c|
  c.mock_with :rspec
end
require 'puppetlabs_spec_helper/module_spec_helper'
```

or by using Puppet Development Kit's [`mock_with` option in `.sync.yml`](https://github.com/puppetlabs/pdk-templates#specspec_helperrb) and `pdk update`.

You can also continue to use mocha by explicitly specifying `:mocha`, following the [mocha documentation](http://gofreerange.com/mocha/docs/).

Migration
---------

To migrate from mocha to rspec-mocks, in many simple cases the following two kinds of changes are all you need:

Translate all stubs:
```
context.stubs(:some_method).with(arguments).returns('value')
```
to this:
```
allow(context).to receive(:some_method).with(arguments).and_return('value')
```

Translate all expectations:
```
context.expects(:some_method).with(arguments).returns('value')
```
to this:
```
expect(context).to receive(:some_method).with(arguments).and_return('value')
```

Rationale
---------

* As a part of the RSpec project, rspec-mocks integration is better.
* mocha is extending base ruby objects with its `stubs`, and `expects` methods, polluting the global namespace, with a potential for subtle and gnarly errors.
* Currently both rspec-mocks and mocha get loaded, leading to test suites that use both.
* puppetlabs_spec_helper loads and configures mocha unconditionally, causing friction when a different mocking framework is wanted.
* mocha is an additional dependency to carry.

EOF
