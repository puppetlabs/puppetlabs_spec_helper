require 'rspec-puppet'
require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

def param_value(subject, type, title, param)
  subject.resource(type, title).send(:parameters)[param.to_sym]
end

def verify_contents(subject, title, expected_lines)
  content = subject.resource('file', title).send(:parameters)[:content]
  expect(content.split("\n") & expected_lines).to match_array expected_lines.uniq
end

spec_path = File.expand_path(File.join(Dir.pwd, 'spec'))
fixture_path = File.join(spec_path, 'fixtures')

env_module_path = ENV['MODULEPATH']
module_path = File.join(fixture_path, 'modules')

module_path = [module_path, env_module_path].join(File::PATH_SEPARATOR) if env_module_path

RSpec.configure do |c|
  c.environmentpath = spec_path if Puppet.version.to_f >= 4.0
  c.module_path = module_path
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.parser = 'future' if ENV['FUTURE_PARSER'] == 'yes'

  c.before :each do
    Puppet.features.stubs(:root?).returns(true)
    # stringify_facts and trusted_node_data were removed in puppet4
    if Puppet.version.to_f < 4.0
      Puppet.settings[:stringify_facts] = false if ENV['STRINGIFY_FACTS'] == 'no'
      Puppet.settings[:trusted_node_data] = true if ENV['TRUSTED_NODE_DATA'] == 'yes'
    end
    Puppet.settings[:strict_variables] = true if ENV['STRICT_VARIABLES'] == 'yes' || (Puppet.version.to_f >= 4.0 && ENV['STRICT_VARIABLES'] != 'no')
    Puppet.settings[:ordering] = ENV['ORDERING'] if ENV['ORDERING']
  end
end
