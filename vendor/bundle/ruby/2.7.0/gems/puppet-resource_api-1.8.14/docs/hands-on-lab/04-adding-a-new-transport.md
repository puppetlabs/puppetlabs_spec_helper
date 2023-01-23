# Add a new transport

Starting with PDK 1.12.0 there is the `pdk new transport` command, that you can use to create the base files for your new transport:

Next, we'll active a few future defaults. In the `hue_workshop` directory, create a file called `.sync.yml` and paste the following:

```
# .sync.yml
---
Gemfile:
  optional:
    ':development':
      - gem: 'puppet-resource_api'
      - gem: 'faraday'
      - gem: 'rspec-json_expectations'
spec/spec_helper.rb:
  mock_with: ':rspec'
```

Run `pdk update` in the module's directory to deploy the changes in the module:

```
david@davids:~/tmp/hue_workshop$ pdk update --force
pdk (INFO): Updating david-hue_workshop using the default template, from 1.10.0 to 1.10.0

----------Files to be modified----------
Gemfile
spec/spec_helper.rb

----------------------------------------

You can find a report of differences in update_report.txt.

Do you want to continue and make these changes to your module? Yes

------------Update completed------------

2 files modified.

david@davids:~/tmp/hue_workshop$
```

Then, create the actual transport:

```
david@davids:~/tmp/hue$ pdk new transport hue
pdk (INFO): Creating '/home/david/tmp/hue/lib/puppet/transport/hue.rb' from template.
pdk (INFO): Creating '/home/david/tmp/hue/lib/puppet/transport/schema/hue.rb' from template.
pdk (INFO): Creating '/home/david/tmp/hue/lib/puppet/util/network_device/hue/device.rb' from template.
pdk (INFO): Creating '/home/david/tmp/hue/spec/unit/puppet/transport/hue_spec.rb' from template.
pdk (INFO): Creating '/home/david/tmp/hue/spec/unit/puppet/transport/schema/hue_spec.rb' from template.
david@davids:~/tmp/hue$
```

## Checkpoint

To validate your new module and transport, run `pdk validate --parallel` and `pdk test unit`:

```
david@davids:~/tmp/hue$ pdk validate --parallel
pdk (INFO): Running all available validators...
pdk (INFO): Using Ruby 2.5.5
pdk (INFO): Using Puppet 6.4.2
┌ [✔] Validating module using 5 threads ┌
├──[✔] Checking metadata syntax (metadat├──son tasks/*.json).
├──[✔] Checking task names (tasks/**/*).├──
└──[✔] Checking YAML syntax (["**/*.yaml├──"*.yaml", "**/*.yml", "*.yml"]).
└──[/] Checking module metadata style (metadata.json).
└──[✔] Checking module metadata style (metadata.json).
info: puppet-syntax: ./: Target does not contain any files to validate (**/*.pp).
info: task-metadata-lint: ./: Target does not contain any files to validate (tasks/*.json).
info: puppet-lint: ./: Target does not contain any files to validate (**/*.pp).
david@davids:~/tmp/hue$ pdk test unit
pdk (INFO): Using Ruby 2.5.5
pdk (INFO): Using Puppet 6.4.2
[✔] Preparing to run the unit tests.
[✔] Running unit tests in parallel.
Run options: exclude {:bolt=>true}
  Evaluated 6 tests in 2.405066937 seconds: 0 failures, 0 pending.
david@davids:~/tmp/hue$
```

If you're working with a version control system, now would be a good time to make your first commit and store the boilerplate code, and then you can revisit the changes you made later. For example:

```
david@davids:~/tmp/hue$ git init
Initialized empty Git repository in ~/tmp/hue/.git/
david@davids:~/tmp/hue$ git add -A
david@davids:~/tmp/hue$ git commit -m 'initial commit'
[main (root-commit) 67951dd] initial commit
 26 files changed, 887 insertions(+)
 create mode 100644 .fixtures.yml
 create mode 100644 .gitattributes
 create mode 100644 .gitignore
 create mode 100644 .gitlab-ci.yml
 create mode 100644 .pdkignore
 create mode 100644 .puppet-lint.rc
 create mode 100644 .rspec
 create mode 100644 .rubocop.yml
 create mode 100644 .sync.yml
 create mode 100644 .travis.yml
 create mode 100644 .yardopts
 create mode 100644 CHANGELOG.md
 create mode 100644 Gemfile
 create mode 100644 README.md
 create mode 100644 Rakefile
 create mode 100644 appveyor.yml
 create mode 100644 data/common.yaml
 create mode 100644 hiera.yaml
 create mode 100644 lib/puppet/transport/hue.rb
 create mode 100644 lib/puppet/transport/schema/hue.rb
 create mode 100644 lib/puppet/util/network_device/hue/device.rb
 create mode 100644 metadata.json
 create mode 100644 spec/default_facts.yml
 create mode 100644 spec/spec_helper.rb
 create mode 100644 spec/unit/puppet/transport/hue_spec.rb
 create mode 100644 spec/unit/puppet/transport/schema/hue_spec.rb
david@davids:~/tmp/hue$
```

## Next up

Now that you have everything ready, you'll [implement the transport](./05-implementing-the-transport.md).
