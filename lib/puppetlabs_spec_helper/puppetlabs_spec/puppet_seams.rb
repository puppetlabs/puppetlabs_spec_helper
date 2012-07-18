# This method is intended to provide seams to break dependency on core Puppet
# internals.  A seam in this context is defined to be, "A seam is a place where
# you can alter behavior in your program with editing in that place." (Working
# Effectively with Legacy Code p31)

# Initialize puppet for testing by loading the 'puppetlabs_spec_helper/puppet_spec_helper' library
require 'puppetlabs_spec_helper/puppet_spec_helper'

module PuppetlabsSpec
  module PuppetSeams
    # parser_scope is intended to return a Puppet::Parser::Scope
    # instance suitable for placing in a test harness with the intent of
    # testing parser functions from modules.
    def self.parser_scope(node_name="localhost")
      if Puppet::Parser::Scope.respond_to? :new_for_test_harness
        Puppet::Parser::Scope.new_for_test_harness(node_name)
      else
        case Puppet.version
        when /^2.6/, /^2.7/
          Puppet::Parser::Functions.autoloader.loadall
        end
        node = Puppet::Node.new(node_name)
        compiler = Puppet::Parser::Compiler.new(node)
        scope = Puppet::Parser::Scope.new(:compiler => compiler)
        scope.source = Puppet::Resource::Type.new(:node, node_name)
        scope
      end
    end
  end
end
