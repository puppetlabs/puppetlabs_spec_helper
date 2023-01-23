require_relative '../../puppet/indirector/face'
Puppet::Indirector::Face.define(:node, '0.0.1') do
  copyright "Puppet Inc.", 2011
  license   _("Apache 2 license; see COPYING")

  summary _("View and manage node definitions.")
  description <<-'EOT'
    This subcommand interacts with node objects, which are used by Puppet to
    build a catalog. A node object consists of the node's facts, environment,
    node parameters (exposed in the parser as top-scope variables), and classes.
  EOT

  deactivate_action(:destroy)
  deactivate_action(:search)
  deactivate_action(:save)

  find = get_action(:find)
  find.summary _("Retrieve a node object.")
  find.arguments _("<host>")
  #TRANSLATORS the following are specific names and should not be translated `classes`, `environment`, `expiration`, `name`, `parameters`, Puppet::Node
  find.returns _(<<-'EOT')
    A hash containing the node's `classes`, `environment`, `expiration`, `name`,
    `parameters` (its facts, combined with any ENC-set parameters), and `time`.
    When used from the Ruby API: a Puppet::Node object.

    RENDERING ISSUES: Rendering as string and json are currently broken;
    node objects can only be rendered as yaml.
  EOT
  find.examples <<-'EOT'
    Retrieve an "empty" (no classes, no ENC-imposed parameters, and an
    environment of "production") node:

    $ puppet node find somenode.puppetlabs.lan --terminus plain --render-as yaml

    Retrieve a node using the Puppet Server's configured ENC:

    $ puppet node find somenode.puppetlabs.lan --terminus exec --run_mode server --render-as yaml

    Retrieve the same node from the Puppet Server:

    $ puppet node find somenode.puppetlabs.lan --terminus rest --render-as yaml
  EOT
end
