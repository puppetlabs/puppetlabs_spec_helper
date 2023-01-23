# Implementing the provider

To expose resources from the HUE Hub to Puppet, a type and provider define and implement the desired interactions. The *type*, like the transport schema, defines the shape of the data using Puppet data types. The implementation in the *provider* takes care of the communication and data transformation.

For this hands on lab, we'll now go through implementing a simple `hue_light` type and provider to manage the state of the light bulbs connected to the HUE Hub.

## Generating the Boilerplate

In your module directory, run `pdk new provider hue_light`. This creates another set of files with a bare-bones type and provider, as well as unit tests.

```
david@davids:~/tmp/hue_workshop$ pdk new provider hue_light
pdk (INFO): Creating '/home/david/tmp/hue_workshop/lib/puppet/provider/hue_light/hue_light.rb' from template.
pdk (INFO): Creating '/home/david/tmp/hue_workshop/lib/puppet/type/hue_light.rb' from template.
pdk (INFO): Creating '/home/david/tmp/hue_workshop/spec/unit/puppet/provider/hue_light/hue_light_spec.rb' from template.
pdk (INFO): Creating '/home/david/tmp/hue_workshop/spec/unit/puppet/type/hue_light_spec.rb' from template.
david@davids:~/tmp/hue_workshop$
```

## Defining the type

The type defines the attributes and allowed values, as well as a couple of other bits of information that concerns the processing of this provider.

For remote resources like this, adding the `'remote_resource'` feature is necessary to alert Puppet of its specific needs. Add the string to the existing `features` array:

```
features: ['remote_resource'],
attributes: {
```

Browsing through the Hub API (TODO: insert link), we can identify a few basic properties we want to manage, for example:

* Whether the lamp is on or off
* The colour of the light (hue and saturation)
* The brightness of the light

To define the necessary attributes, insert the following snippet into the `attributes` hash, after the `name`:

```
    ensure:     {
      type:     'Enum[present, absent]',
      desc:     'Whether this resource should be present or absent on the target system.',
      default:  'present',      
    },
    on:         {
      type:     'Optional[Boolean]',
      desc:     'Switches the light on or off',
    },
    hue:        {
      type:     'Optional[Integer]',
      desc:     'The hue the light color.',
    },
    sat:        {
      type:     'Optional[Integer]',
      desc:     'The saturation of the light colour',
    },
    bri:        {
      type:     'Optional[Integer[1,254]]',
      desc:     <<DESC,
  This is the brightness of a light from its minimum brightness 1 to its maximum brightness 254
DESC
    },
```

## Implementing the Provider

Every provider needs a `get` method, that returns a list of currently existing resources and their attributes from the remote target. For the HUE Hub, this is requires a call to the `lights` endpoint and some data transformation to the format Puppet expects.

### Reading the state of the lights

Replace the example `get` function in `lib/puppet/provider/hue_light/hue_light.rb` with the following code:

```
  # @summary
  #    Returns a list of lights and their attributes as a list of hashes.
  def get(context)
    lights = context.transport.hue_get(context, 'lights')

    return [] if lights.nil?

    lights.collect { |name, content|
      {
        name: name,
        ensure: 'present',
        on: content['state']['on'],
        hue: content['state']['hue'],
        sat: content['state']['sat'],
        bri: content['state']['bri'],
      }
    }
  end
```

This method returns all connected lights from the HUE Hub and allows Puppet to process them. To try this out, you need to setup a test configuration and use `puppet device` to drive your testing.

### Obtaining an API key from the Philips Hue Bridge API
We will need to create an authorized user on the Bridge API, which in turn will provide us with a token we can use for subsequent requests:
- Press the 'Link' button on the Bridge device (**NOTE:** Linking expires after 10 seconds of inactivity by default)
- Perform the following POST request to the API using curl:
```
curl -X POST -d '{"devicetype":"puppetlabs#hue_light_mgmt"}' 'http://192.168.43.195:8000/api'
```
If that has been successful, we should get a `200` response with the user's API token:
```
[
  { "success":
    { 
      "username": "onmdTvd198bMrC6QYyVE9iasfYSeyAbAj3XyQzfL"
    }
  }
]
```

# hub1.conf
```
host: 192.168.43.195
key: onmdTvd198bMrC6QYyVE9iasfYSeyAbAj3XyQzfL
```

```
# device.conf
[hub1]
type hue
url  file:///home/david/git/hue_workshop/spec/fixtures/hub1.conf

[hub2]
type hue
url  file:///home/david/git/hue_workshop/spec/fixtures/hub2.conf
```

```
david@davids:~/tmp/hue_workshop$ pdk bundle install
pdk (INFO): Using Ruby 2.4.5
pdk (INFO): Using Puppet 5.5.12
[...]
Bundle complete! 10 Gemfile dependencies, 90 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

david@davids:~/tmp/hue_workshop$ pdk bundle exec puppet device --libdir lib --deviceconfig device.conf --target hub1 --resource hue_light
pdk (INFO): Using Ruby 2.4.5
pdk (INFO): Using Puppet 5.5.12
hue_light { '1':
  on => true,
  bri => 37,
  hue => 13393,
  sat => 204,
  effect => 'none',
  alert => 'select',
}
hue_light { '2':
  on => true,
  bri => 37,
  hue => 13401,
  sat => 204,
  effect => 'none',
  alert => 'select',
}
hue_light { '3':
  on => true,
  bri => 254,
  hue => 65136,
  sat => 254,
  effect => 'none',
  alert => 'none',
}

david@davids:~/tmp/hue_workshop$
```

### Changing the state of the lights

The final step here is to implement enforcing the desired state of the lights. The default template from the PDK offers `create`, `update`, and `delete` methods to implement the various operations.

For the HUE Hub API, we can remove the `create` and `delete` method. Since the attribute names and data definitions line up with the HUE Hub API, the `update` method is very short.

Replace the `create`, `update`, and `delete` methods with the following code:

```
  def update(context, name, should)
    context.device.hue_put("lights/#{name}/state", should)
  end
```

Now you can also change the state of the lights using a manifest:

```
# traffic_lights.pp
Hue_light { on => true, bri => 10, sat => 254 }
hue_light {
  '1':
    hue => 23536;
  '2':
    hue => 10000;
  '3':
    hue => 65136;
}
```

```
david@davids:~/git/hue_workshop$ pdk bundle exec puppet device --libdir lib --deviceconfig device.conf --target hub1 --apply examples/traffic_lights.pp
pdk (INFO): Using Ruby 2.4.5
pdk (INFO): Using Puppet 5.5.12
Notice: Compiled catalog for hub1 in environment production in 0.06 seconds
Notice: /Stage[main]/Main/Hue_light[1]/hue: hue changed 13393 to 23536 (corrective)
Notice: /Stage[main]/Main/Hue_light[1]/bri: bri changed 70 to 10 (corrective)
Notice: /Stage[main]/Main/Hue_light[1]/sat: sat changed 204 to 255 (corrective)
Notice: /Stage[main]/Main/Hue_light[2]/hue: hue changed 13401 to 10000 (corrective)
Notice: /Stage[main]/Main/Hue_light[2]/bri: bri changed 70 to 10 (corrective)
Notice: /Stage[main]/Main/Hue_light[2]/sat: sat changed 204 to 255 (corrective)
Notice: /Stage[main]/Main/Hue_light[3]/bri: bri changed 254 to 10 (corrective)
Notice: /Stage[main]/Main/Hue_light[3]/sat: sat changed 254 to 255 (corrective)
Notice: Applied catalog in 0.18 seconds

david@davids:~/git/hue_workshop$
```

## Exercise

To round out the API support, add an `effect` attribute that defaults to `none`, but can be set to `colorloop`, and an `alert` attribute that defaults to `none` and can be set to `select`.

Note that this exercise requires exploring new data types and Resource API options.

> TODO: add exercise hints

# Next Up

Now that we can manage state, it's time to [implement a task](./07-implementing-a-task.md) to do some fun transient things with the lights.
