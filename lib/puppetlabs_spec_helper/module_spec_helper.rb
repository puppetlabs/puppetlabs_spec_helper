require 'rspec-puppet'
require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

def param_value(subject, type, title, param)
  subject.resource(type, title).send(:parameters)[param.to_sym]
end

def verify_contents(subject, title, expected_lines)
  content = subject.resource('file', title).send(:parameters)[:content]
  (content.split("\n") & expected_lines).should == expected_lines
end

fixture_path = File.expand_path(File.join(Dir.pwd, 'spec/fixtures'))

env_module_path = ENV['MODULEPATH']
module_path = File.join(fixture_path, 'modules')

module_path = [module_path, env_module_path].join(File::PATH_SEPARATOR) if env_module_path

RSpec.configure do |c|
  c.module_path = module_path
  c.manifest_dir = File.join(fixture_path, 'manifests')
  ## These depend on rspec-puppet #209 and #183 being released
  #c.parser = 'future' if ENV['FUTURE_PARSER'] == 'yes'
  #c.strict_variables = true if ENV['STRICT_VARIABLES'] == 'yes'

  c.before :each do
    Puppet.settings[:strict_variables] = true if ENV['STRICT_VARIABLES'] == 'yes'
    Puppet.settings[:parser] = 'future' if ENV['FUTURE_PARSER'] == 'yes'
  end
end
