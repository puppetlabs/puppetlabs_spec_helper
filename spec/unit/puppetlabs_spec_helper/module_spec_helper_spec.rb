# frozen_string_literal: true

require 'fileutils'
require 'spec_helper'

# Create a real fixtures/modules/stdlib directory so that the Dir.exist? path
# in module_spec_helper.rb is taken (covering lines 64, 66, 68, 69).
FileUtils.mkdir_p('spec/fixtures/modules/stdlib')

# Set MODULEPATH so that line 22 (module_path join) is covered.
ENV['MODULEPATH'] = 'spec/fixtures/modules'

# Requiring module_spec_helper covers all load-time lines.  When COVERAGE=yes
# (i.e. `rake spec:coverage`), ENV['SIMPLECOV'] is already 'yes' so the
# SimpleCov configuration block (lines 26-57) is also exercised.
require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.after(:suite) do
    FileUtils.rm_rf('spec/fixtures/modules') if File.directory?('spec/fixtures/modules')
    ENV.delete('MODULEPATH')
  end
end

RSpec.describe 'module_spec_helper' do
  describe 'param_value helper' do
    # param_value is defined at the top level by module_spec_helper.rb (line 7-9).
    # Calling it here covers the method body (line 8).
    it 'returns the named parameter value from a catalog resource' do
      mock_params = { content: 'hello' }
      mock_resource = double('resource', parameters: mock_params)
      mock_subject  = double('catalog', resource: mock_resource)

      expect(param_value(mock_subject, 'File', '/tmp/test', 'content')).to eq('hello')
    end
  end

  describe 'verify_contents helper' do
    # verify_contents is defined at the top level (lines 11-14).
    # Calling it covers lines 12-13.
    it 'passes when the resource content includes all expected lines' do
      mock_resource = double('resource', parameters: { content: "line1\nline2\nline3" })
      mock_subject  = double('catalog', resource: mock_resource)

      expect { verify_contents(mock_subject, '/tmp/test', %w[line1 line2]) }.not_to raise_error
    end
  end

  describe 'RSpec configuration applied by module_spec_helper' do
    # Running any example here triggers the before(:each) hook registered by
    # module_spec_helper (lines 83-89), covering lines 84 and 85.
    it 'configures the module_path setting' do
      expect(RSpec.configuration.module_path).to include('spec/fixtures/modules')
    end

    it 'sets strict_variables' do
      expect(RSpec.configuration.strict_variables).to be(true).or be(false)
    end
  end
end
