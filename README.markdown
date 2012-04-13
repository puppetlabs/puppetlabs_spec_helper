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

When developing or testing modules, simply clone this repository, make it
available in the `$LOAD_PATH`, and require 'puppet_spec_helper'.

    $ git clone git://github.com/puppetlabs/puppetlabs_spec_helper.git
    $ export RUBYLIB="$(pwd)/puppetlabs_spec_helper:${RUBYLIB}"

Add this to your project's spec_helper.rb:

    require 'puppet_spec_helper'

    $ cd stdlib
    $ rake test

Issues
======

Please file issues against this project at the [Puppet Labs Issue
Tracker](http://projects.puppetlabs.com/issues/13595)

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
   tempfiles, common rspec matchers, etc.  These classes are in the puppetlabs_spec
   directory.

To Use this Project
===================

The most common usage scenario is that you will check out the 'master' branch of
this project from github, and ensure that the root directory of the project
is added to your RUBYLIB.  There should be few or no cases where you would want
to have any other branch of this project besides master/HEAD.

Main Files in this Project
==========================

1. puppet_spec_helper.rb: 'require' this file if you have a dependency on puppet core,
   and you need to initialize puppet for testing.
2. puppetlabs_spec_helper.rb: 'require' this file if you don't have a dependency on
   puppet core, but you wish to use some of the utility classes and methods
   bundled in the puppetlabs_spec directory of this project.

Initializing Puppet for Testing
===============================

In most cases, your project should be able to define a spec_helper.rb that includes
just this one simple line:

    require 'puppet_spec_helper'

Then, as long as the root directory of the puppetlabs_spec_helper project is in
your RUBYLIB, you should be all set.

NOTE that this is specifically for initializing Puppet's core.  If your project does
not have any dependencies on puppet and you just want to use the utility classes,
see the next section.


Using Utility Classes
=====================
If you'd like to use the Utility classes (PuppetlabsSpec::Files,
PuppetlabsSpec::Fixtures), you just need to add this to your project's spec_helper.rb:

    require 'puppetlabs_spec_helper'

NOTE that the above line happens automatically if you've required
'puppet_spec_helper', so you don't need to do both.

In either case, you'll have all of the functionality of Puppetlabs::Files,
Puppetlabs::Fixtures, etc., mixed-in to your rspec context.

