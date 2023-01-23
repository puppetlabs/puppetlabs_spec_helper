# Implementing the transport

A transport consists of a *schema* describing the required data and credentials to connect to the HUE hub, and the *implementation* containing all the code to facilitate communication with the devices.

## Schema

The transport schema defines attributes in a reusable way, allowing you to understand the requirements of the transport. All schemas are located in `lib/puppet/transport/schema` in a Ruby file named after the transport. In this case `hue.rb`.

To connect to the HUE hub you need an IP address, a port, and an API key.

Replace the `connection_info` in `lib/puppet/transport/schema/hue.rb` with the following code:

```ruby
  connection_info: {
    host: {
      type: 'String',
      desc: 'The FQDN or IP address of the hue light system to connect to.',
    },
    port: {
      type: 'Optional[Integer]',
      desc: 'The port to use when connecting, defaults to 80.',
    },
    key: {
      type: 'String',
      desc: 'The access key that allows access to the hue light system.',
      sensitive: true,
    },
  },
```

> Note: The Resource API transports use [Puppet Data Types](https://puppet.com/docs/puppet/5.3/lang_data_type.html#core-data-types) to define the allowable values for an attribute. Abstract types like `Optional[]` can be useful to make using your transport easier. Take note of the `sensitive: true` annotation on the `key`; it instructs all services processing this attribute with special care, for example to avoid logging the key.


## Implementation

The implementation of a transport provides connectivity and utility functions for both Puppet and the providers managing the remote target. The HUE API is a simple REST interface, so you can store the credentials until you need make a connection. The default template at `lib/puppet/transport/hue.rb` already does this. Have a look at the `initialize` function to see how this is done.

For the HUE's REST API, we want to create a `Faraday` object to capture the target host and key so that the transport can facilitate requests. Replace the `initialize` method in `lib/puppet/transport/hue.rb` with the following code:

<!-- TODO: do we really need this? -- probably not ```
    # @summary
    #   Expose the `Faraday` object connected to the hub
    attr_reader :connection

```-->
```
    # @summary
    #   Initializes and returns a faraday connection to the given host
    def initialize(_context, connection_info)
      # provide a default port
      port = connection_info[:port].nil? ? 80 : connection_info[:port]
      Puppet.debug "Connecting to #{connection_info[:host]}:#{port} with dev key"
      @connection = Faraday.new(url: "http://#{connection_info[:host]}:#{port}/api/#{connection_info[:key].unwrap}", ssl: { verify: false })
    end
```

> Note the `unwrap` call on building the URL, to access the sensitive value.

### Facts

The transport is also responsible for collecting any facts from the remote target, similar to how facter works for regular systems. For now we'll only return a hardcoded `operatingsystem` value to mark HUE Hubs:

Replace the example `facts` method in `lib/puppet/transport/hue.rb` with the following code:

```
    # @summary
    #   Returns set facts regarding the HUE Hub
    def facts(_context)
      { 'operatingsystem' => 'philips_hue' }
    end
```

### Connection verification and closing

To enable better feedback when something goes wrong, a transport can implement a `verify` method to run extra checks on the credentials passed in.

To save resources both on the target and the node running the transport, the `close` method will be called when the transport is not needed anymore. The transport can close connections and release memory and other resources at this point.

For this tutorial, replace the example methods with the following code:

```
    # @summary
    #   Test that transport can talk to the remote target
    def verify(_context)
    end

    # @summary
    #   Close connection, free up resources
    def close(_context)
      @connection = nil
    end
```

### Making requests

Besides exposing some standardises functionality to Puppet, the transport is also a good place to put utility functions that can be reused across your providers. While it may seem overkill for this small example, it is no extra effort, and will establish a healthy pattern.

Insert the following code after the `close` method:

```
    # @summary
    #   Make a get request to the HUE Hub API
    def hue_get(context, url, args = nil)
      url = URI.escape(url) if url
      result = @connection.get(url, args)
      JSON.parse(result.body)
    rescue JSON::ParserError => e
      raise Puppet::ResourceError, "Unable to parse JSON response from HUE API: #{e}"
    end

    # @summary
    #   Sends an update command to the given url/connection
    def hue_put(context, url, message)
      message = message.to_json
      @connection.put(url, message)
    end
```

## Exercise

Implement a `request_debug` option that you can toggle to create additional debug output on each request. If you get stuck, have a look at [some hints](./05-implementing-the-transport-hints.md), or [the finished file](TODO).


# Next Up

Now that the transport can talk to the remote target, it's time to [implement a provider](./06-implementing-the-provider.md).
