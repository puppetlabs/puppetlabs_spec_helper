# Implementing a Task

> TODO: this is NOT fine, yet

* add bolt gem
```
Gemfile:
  optional:
    ':development':
      - gem: 'puppet-resource_api'
      - gem: 'faraday'
      # add this
      - gem: 'bolt'
```


```
david@davids:~/tmp/hue_workshop$ pdk update --force
pdk (INFO): Updating david-hue_workshop using the default template, from 1.10.0 to 1.10.0

----------Files to be modified----------
Gemfile

----------------------------------------

You can find a report of differences in update_report.txt.


------------Update completed------------

1 files modified.

david@davids:~/tmp/hue_workshop$ pdk bundle install
pdk (INFO): Using Ruby 2.5.3
pdk (INFO): Using Puppet 6.4.2
[...]
Bundle complete! 11 Gemfile dependencies, 122 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

david@davids:~/tmp/hue_workshop$
```

* add ruby_task_helper module
<!--
```# .fixtures.yml
---
fixtures:
  forge_modules:
     ruby_task_helper: "puppetlabs/ruby_task_helper"
```

```
david@davids:~/tmp/hue_workshop$ pdk bundle exec rake spec_prep
pdk (INFO): Using Ruby 2.5.3
pdk (INFO): Using Puppet 6.4.2
Notice: Preparing to install into /home/david/tmp/hue_workshop/spec/fixtures/modules ...
Notice: Downloading from https://forgeapi.puppet.com ...
Notice: Installing -- do not interrupt ...
/home/david/tmp/hue_workshop/spec/fixtures/modules
└── puppetlabs-ruby_task_helper (v0.3.0)
I, [2019-06-04T13:12:04.615368 #32070]  INFO -- : Creating symlink from spec/fixtures/modules/hue_workshop to /home/david/tmp/hue_workshop
david@davids:~/tmp/hue_workshop$
``` -->

Using the development version:

```
fixtures:
  # forge_modules:
  #    ruby_task_helper: "puppetlabs/ruby_task_helper"
  repositories:
    ruby_task_helper:
      repo: "git://github.com/da-ar/puppetlabs-ruby_task_helper"
      ref: "38745f8e7c2521c50bbf1b8e03318006cdac7a02"
```

```
david@davids:~/tmp/hue_workshop$ pdk bundle exec rake spec_prep
pdk (INFO): Using Ruby 2.5.3
pdk (INFO): Using Puppet 6.4.2
HEAD is now at 38745f8 (FM-7955) Update to use Transport helper code
Cloning into 'spec/fixtures/modules/ruby_task_helper'...
I, [2019-06-04T13:43:58.577944 #9390]  INFO -- : Creating symlink from spec/fixtures/modules/hue_workshop to /home/david/tmp/hue_workshop
david@davids:~/tmp/hue_workshop$
```

* `pdk new task` based on https://github.com/puppetlabs/puppetlabs-panos/blob/main/tasks/apikey.rb

```
david@davids:~/tmp/hue_workshop$ pdk new task alarm
pdk (INFO): Creating '/home/david/tmp/hue_workshop/tasks/alarm.sh' from template.
pdk (INFO): Creating '/home/david/tmp/hue_workshop/tasks/alarm.json' from template.
david@davids:~/tmp/hue_workshop$ mv /home/david/tmp/hue_workshop/tasks/alarm.sh /home/david/tmp/hue_workshop/tasks/alarm.rb
david@davids:~/tmp/hue_workshop$
```

* `tasks/alarm.json`
```json
{
  "puppet_task_version": 1,
  "supports_noop": false,
  "remote": true,
  "description": "A short description of this task",
  "parameters": {
    "name": {
      "type": "String",
      "description": "The lamp to alarm"
    }
  },
  "files": [
    "ruby_task_helper/files/task_helper.rb",
    "hue_workshop/lib/puppet/transport/hue.rb",
    "hue_workshop/lib/puppet/transport/schema/hue.rb"
  ]
}
```

* `tasks/alarm.rb`

```ruby
#!/opt/puppetlabs/puppet/bin/ruby

require 'puppet'
require_relative "../../ruby_task_helper/files/task_helper.rb"

class AlarmTask < TaskHelper
  def task(params = {}, remote = nil)
    name = params[:name]
    5.times do |i|
      remote.transport.hue_put("lights/#{name}/state",
        name: name,
        on: false,
      )
      sleep 1.0
      remote.transport.hue_put("lights/#{name}/state",
        name: name,
        on: true,
        hue: 10000*i,
        sat: 255
      )
      sleep 1.0
    end
    {}
  end
end

if __FILE__ == $0
  AlarmTask.run
end
```

* execute `pdk bundle exec bolt ...`

```yaml
# inventory.yaml
---
nodes:
  - name: "192.168.43.195"
    alias: hub1
    config:
      transport: remote
      remote:
        remote-transport: hue
        key: "onmdTvd198bMrC6QYyVE9iasfYSeyAbAj3XyQzfL"
```

```
david@davids:~/tmp/hue_workshop$ pdk bundle exec bolt task run hue_workshop::alarm --modulepath spec/fixtures/modules/ --target hub1 --inventoryfile inventory.yaml
pdk (INFO): Using Ruby 2.5.3
pdk (INFO): Using Puppet 6.4.2
Started on 192.168.43.195...
Finished on 192.168.43.195:
  {
  }
Successful on 1 node: 192.168.43.195
Ran on 1 node in 11.32 seconds

david@davids:~/tmp/hue_workshop$
```

* profit!
