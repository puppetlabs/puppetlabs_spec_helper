def param_value(subject, type, title, param)
  subject.resource(type, title).send(:parameters)[param.to_sym]
end

def verify_contents(subject, title, expected_lines)
  content = subject.resource('file', title).send(:parameters)[:content]
  (content.split("\n") & expected_lines).should == expected_lines
end

RSpec.configure do |config|
  # Include PuppetlabsSpecHelper helpers so they can be called at convenience
  config.extend PuppetlabsSpecHelper::Files
  config.extend PuppetlabsSpecHelper::Fixtures
  config.include PuppetlabsSpecHelper::Fixtures

  fixture_path = File.expand_path(File.join(Dir.pwd, 'spec/fixtures'))

  env_module_path = ENV['MODULEPATH']
  module_path = File.join(fixture_path, 'modules')

  module_path = [module_path, env_module_path].join(File::PATH_SEPARATOR) if env_module_path

  config.module_path = module_path
  config.manifest_dir = File.join(fixture_path, 'manifests')

  # This will cleanup any files that were created with tmpdir or tmpfile
  config.after do
    PuppetlabsSpecHelper::Files.cleanup
  end
end
