require 'spec_helper'

describe SetupBeaker do
  describe '.setup_beaker' do
    let(:task) {RSpec::Core::RakeTask.new}
    it 'can set tag for low tier' do
      allow(ENV).to receive(:[]).and_return('low')
      expect(SetupBeaker.setup_beaker(task).rspec_opts.to_s).to match(/--tag tier_low/)
    end
    it 'can set tag for high, medium and low tier' do
      allow(ENV).to receive(:[]).and_return('high, medium, low')
      expect(SetupBeaker.setup_beaker(task).rspec_opts.to_s).to match(/--tag tier_high/ && /--tag tier_medium/ && /--tag tier_low/)
    end
    it 'does not set a tag when ENV[TEST_TIERS] is nil' do
      allow(ENV).to receive(:[]).and_return(nil)
      expect(SetupBeaker.setup_beaker(task).rspec_opts.to_s).to_not match(/--tag/)
    end
    it 'errors when tier specified does not exist' do
      allow(ENV).to receive(:[]).and_return('expect_error')
      expect{SetupBeaker.setup_beaker(task)}.to raise_error(RuntimeError, /not a valid test tier/)
    end
    it 'errors when tiers are quoted' do
      allow(ENV).to receive(:[]).and_return('"high", "medium", "low"')
      expect{SetupBeaker.setup_beaker(task)}.to raise_error(RuntimeError, /not a valid test tier/)
    end
  end
end

describe PuppetlabsSpecHelper::RakeTasks do
  describe '.fixtures' do
    before :each do
      # Unstub the fixtures "helpers"
      PuppetlabsSpec::Fixtures.instance_methods.each do |m|
        PuppetlabsSpec::Fixtures.send(:undef_method, m)
      end
      allow(File).to receive(:exists?).with('.fixtures.yml').and_return false
      allow(File).to receive(:exists?).with('.fixtures.yaml').and_return false
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return(nil)
      allow(PuppetlabsSpecHelper::RakeTasks).to receive(:auto_symlink).and_return({ 'project' => '#{source_dir}' })
    end
    context 'when file is missing' do
      it 'returns basic directories per category' do
        expect(subject.fixtures("forge_modules")).to eq({})
        expect(subject.fixtures("repositories")).to eq({})
      end
    end
    context 'when file is empty' do
      it 'returns basic directories per category' do
        allow(File).to receive(:exists?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return false
        expect(subject.fixtures("forge_modules")).to eq({})
        expect(subject.fixtures("repositories")).to eq({})
      end
    end
    context 'when file is malformed' do
      it 'raises an error' do
        allow(File).to receive(:exists?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_raise(Psych::SyntaxError.new('/file', '123', '0', '0', 'spec message', 'spec context'))
        expect { subject.fixtures("forge_modules") }.to raise_error(RuntimeError, /malformed YAML/)
      end
    end
    context 'when file contains no fixtures' do
      it 'raises an error' do
        allow(File).to receive(:exists?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return({'some' => 'key'})
        expect { subject.fixtures("forge_modules") }.to raise_error(RuntimeError, /No 'fixtures'/)
      end
    end
    context 'when file specifies fixtures' do
      it 'returns the hash' do
        allow(File).to receive(:exists?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return({'fixtures' => { 'forge_modules' => { 'stdlib' => 'puppetlabs-stdlib'}}})
        expect(subject.fixtures("forge_modules")).to eq({
          'puppetlabs-stdlib' => {
            'target' => 'spec/fixtures/modules/stdlib',
            'ref'    => nil,
            'branch' => nil,
            'scm'    => nil,
            'flags'  => nil,
            'subdir' => nil,
          }
        })
      end
    end
    context 'when file specifies defaults' do
      it 'returns the hash' do
        allow(File).to receive(:exists?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return({
          'defaults' => { 'forge_modules' => { 'flags' => '--module_repository=https://myforge.example.com/' }},
          'fixtures' => { 'forge_modules' => { 'stdlib' => 'puppetlabs-stdlib'}}})
        expect(subject.fixtures("forge_modules")).to eq({
          'puppetlabs-stdlib' => {
            'target' => 'spec/fixtures/modules/stdlib',
            'ref'    => nil,
            'branch' => nil,
            'scm'    => nil,
            'flags'  => '--module_repository=https://myforge.example.com/',
            'subdir' => nil,
          }
        })
      end
    end
  end
end
