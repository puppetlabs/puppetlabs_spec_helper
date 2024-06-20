# frozen_string_literal: true

# Initialize puppet for testing by loading the
# 'puppetlabs_spec_helper/puppet_spec_helper' library
require 'puppetlabs_spec_helper/puppet_spec_helper'

module PuppetlabsSpec
  # PuppetInternals provides a set of methods that interface
  # with internal puppet implementations.
  module PuppetInternals
    def resource(parts = {})
      resource_type = parts[:type] || :hostclass
      resource_name = parts[:name] || 'testing'
      Puppet::Resource::Type.new(resource_type, resource_name)
    end
    module_function :resource

    def compiler(parts = {})
      compiler_node = parts[:node] || node
      Puppet::Parser::Compiler.new(compiler_node)
    end
    module_function :compiler

    def node(parts = {})
      node_name = parts[:name] || 'testinghost'
      options = parts[:options] || {}
      node_environment = Puppet::Node::Environment.create(parts[:environment] || 'test', [])
      options[:environment] = node_environment
      Puppet::Node.new(node_name, options)
    end
    module_function :node

    # Return a method instance for a given function.  This is primarily useful
    # for rspec-puppet
    def function_method(name, parts = {})
      scope = parts[:scope] || scope()
      # Ensure the method instance is defined by side-effect of checking if it
      # exists.  This is a hack, but at least it's a hidden hack and not an
      # exposed hack.
      return nil unless Puppet::Parser::Functions.function(name)

      scope.method(:"function_#{name}")
    end
    module_function :function_method
  end
end
