ruby-hocon
==========
[![Gem Version](https://badge.fury.io/rb/hocon.svg)](https://badge.fury.io/rb/hocon) [![Build Status](https://travis-ci.org/puppetlabs/ruby-hocon.png?branch=master)](https://travis-ci.org/puppetlabs/ruby-hocon)

This is a port of the [Typesafe Config](https://github.com/typesafehub/config) library to Ruby.

The library provides Ruby support for the [HOCON](https://github.com/typesafehub/config/blob/master/HOCON.md) configuration file format.


At present, it supports parsing and modification of existing HOCON/JSON files via the `ConfigFactory`
class and the `ConfigValueFactory` class, and rendering parsed config objects back to a String
([see examples below](#basic-usage)). It also supports the parsing and modification of HOCON/JSON files via
`ConfigDocumentFactory`.

**Note:** While the project is production ready, since not all features in the Typesafe library are supported,
you may still run into some issues. If you find a problem, feel free to open a github issue.

The implementation is intended to be as close to a line-for-line port as the two languages allow,
in hopes of making it fairly easy to port over new changesets from the Java code base over time.

Support
=======

For best results, if you find an issue with this library, please open an issue on our [Jira issue tracker](https://tickets.puppetlabs.com/browse/HC).  Issues filed there tend to be more visible to the current maintainers than issues on the Github issue tracker.


Basic Usage
===========

```sh
gem install hocon
```

To use the simple API, for reading config values:

```rb
require 'hocon'

conf = Hocon.load("myapp.conf")
puts "Here's a setting: #{conf["foo"]["bar"]["baz"]}"
```

By default, the simple API will determine the configuration file syntax/format
based on the filename extension of the file; `.conf` will be interpreted as HOCON,
`.json` will be interpreted as strict JSON, and any other extension will cause an
error to be raised since the syntax is unknown.  If you'd like to use a different
file extension, you manually specify the syntax, like this:

```rb
require 'hocon'
require 'hocon/config_syntax'

conf = Hocon.load("myapp.blah", {:syntax => Hocon::ConfigSyntax::HOCON})
```

Supported values for `:syntax` are: JSON, CONF, and HOCON.  (CONF and HOCON are
aliases, and both map to the underlying HOCON syntax.)

To use the ConfigDocument API, if you need both read/write capability for
modifying settings in a config file, or if you want to retain access to
things like comments and line numbers:

```rb
require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'

# The below 4 variables will all be ConfigDocument instances
doc = Hocon::Parser::ConfigDocumentFactory.parse_file("myapp.conf")
doc2 = doc.set_value("a.b", "[1, 2, 3, 4, 5]")
doc3 = doc.remove_value("a")
doc4 = doc.set_config_value("a.b", Hocon::ConfigValueFactory.from_any_ref([1, 2, 3, 4, 5]))

doc_has_value = doc.has_value?("a") # returns boolean
orig_doc_text = doc.render # returns string
```

Note that a `ConfigDocument` is used primarily for simple configuration manipulation while preserving
whitespace and comments. As such, it is not powerful as the regular `Config` API, and will not resolve
substitutions.

CLI Tool
========
The `hocon` gem comes bundles with a `hocon` command line tool which can be used to get and set values from hocon files

```
Usage: hocon [options] {get,set,unset} PATH [VALUE]

Example usages:
  hocon -i settings.conf -o new_settings.conf set some.nested.value 42
  hocon -f settings.conf set some.nested.value 42
  cat settings.conf | hocon get some.nested.value

Subcommands:
  get PATH - Returns the value at the given path
  set PATH VALUE - Sets or adds the given value at the given path
  unset PATH - Removes the value at the given path

Options:
    -i, --in-file HOCON_FILE         HOCON file to read/modify. If omitted, STDIN assumed
    -o, --out-file HOCON_FILE        File to be written to. If omitted, STDOUT assumed
    -f, --file HOCON_FILE            File to read/write to. Equivalent to setting -i/-o to the same file
    -j, --json                       Output values from the 'get' subcommand in json format
    -h, --help                       Show this message
    -v, --version                    Show version
```

CLI Examples
--------
### Basic Usage
```
$ cat settings.conf
{
  foo: bar
}

$ hocon -i settings.conf get foo
bar

$ hocon -i settings.conf set foo baz

$ cat settings.conf
{
  foo: baz
}

# Write to a different file
$ hocon -i settings.conf -o new_settings.conf set some.nested.value 42
$ cat new_settings.conf
{
  foo: bar
  some: {
    nested: {
      value: 42

    }
  }
}

# Write back to the same file
$ hocon -f settings.conf set some.nested.value 42
$ cat settings.conf
{
  foo: bar
  some: {
    nested: {
      value: 42

    }
  }
}
```

### Complex Values
If you give `set` a properly formatted hocon dictionary or array, it will try to accept it

```
$ hocon -i settings.conf set foo "{one: [1, 2, 3], two: {hello: world}}"
{
  foo: {one: [1, 2, 3], two: {hello: world}}
}
```

### Chaining
If `--in-file` or `--out-file` aren't specified, STDIN and STDOUT are used for the missing options. Therefore it's possible to chain `hocon` calls

```
$ cat settings.conf
{
  foo: bar
}

$ cat settings.conf | hocon set foo 42 | hocon set one.two three
{
  foo: 42
  one: {
    two: three
  }
}
```

### JSON Output
Calls to the `get` subcommand will return the data in HOCON format by default, but setting the `-j/--json` flag will cause it to return a valid JSON object

```
$ cat settings.conf
foo: {
  bar: {
    baz: 42
  }
}

$ hocon -i settings.conf get foo --json
{
    "bar": {
        "baz": 42
    }
}
```

Testing
=======

```sh
bundle install --path .bundle
bundle exec rspec spec
```

Unsupported Features
====================

This supports many of the same things as the Java library, but there are some notable exceptions.
Unsupported features include:

* Non file includes
* Loading resources from the class path or URLs
* Properties files
* Parsing anything other than files and strings
* Duration and size settings
* Java system properties

