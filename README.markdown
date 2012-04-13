Puppet Labs Spec Helper
=======================

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

When developing or testing modules, simply clone this repository and make it
available in the `$LOAD_PATH`

    $ git clone git://github.com/puppetlabs/puppetlabs_spec_helper.git
    $ export RUBYLIB="$(pwd)/puppetlabs_spec_helper:${RUBYLIB}"
    $ cd stdlib
    $ rake test

Issues
======

Please file issues against this project at the [Puppet Labs Issue
Tracker](http://projects.puppetlabs.com/issues/13595)
