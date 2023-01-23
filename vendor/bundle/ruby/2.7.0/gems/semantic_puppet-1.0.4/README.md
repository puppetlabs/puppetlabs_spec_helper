SemanticPuppet
==============

Library of useful tools for working with Semantic Versions and module
dependencies.

Description
-----------

Library of tools used by Puppet to parse, validate, and compare Semantic
Versions and Version Ranges and to query and resolve module dependencies.

For sparse, but accurate documentation, please see the docs directory.

This library is used by a number of Puppet Labs projects, including
[Puppet](https://github.com/puppetlabs/puppet) and
[r10k](https://github.com/puppetlabs/r10k).

Requirements
------------

Semantic_puppet will work on several ruby versions, including 1.9.3,
2.0.0, 2.1.9 and 2.4.1. Please see the exact matrix in `.travis.yml`.

No gem/library requirements.

Installation
------------

### Rubygems

For general use, you should install semantic_puppet from Ruby gems:

    gem install semantic_puppet

### Github

If you have more specific needs or plan on modifying semantic_puppet you can
install it out of a git repository:

    git clone git://github.com/puppetlabs/semantic_puppet

Usage
-----

SemanticPuppet is intended to be used as a library.

### Version Range Operator Support

SemanticPuppet will support the same version range operators as those
used when publishing modules to [Puppet
Forge](https://forge.puppetlabs.com) which is documented at [Publishing
Modules on the Puppet
Forge](https://docs.puppetlabs.com/puppet/latest/reference/modules_publishing.html#dependencies-in-metadatajson).

Contributors
------------

Pieter van de Bruggen wrote the library originally. See
[https://github.com/puppetlabs/semantic_puppet/graphs/contributors](https://github.com/puppetlabs/semantic_puppet/graphs/contributors)
for a list of contributors.

## Maintenance

Tickets: File at
[https://tickets.puppet.com/browse/FORGE](https://tickets.puppet.com/browse/FORGE)
