require 'spec_helper'
require 'puppetlabs_spec_helper/tasks/fixtures'

describe PuppetlabsSpecHelper::Tasks::FixtureHelpers do
  describe '.fixtures' do
    before :each do
      # Unstub the fixtures "helpers"
      PuppetlabsSpec::Fixtures.instance_methods.each do |m|
        PuppetlabsSpec::Fixtures.send(:undef_method, m)
      end
      allow(File).to receive(:exist?).with('.fixtures.yml').and_return false
      allow(File).to receive(:exist?).with('.fixtures.yaml').and_return false
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return(nil)
      allow(described_class).to receive(:auto_symlink).and_return('project' => '#{source_dir}')
    end

    context 'when file is missing' do
      it 'returns basic directories per category' do
        expect(subject.fixtures('forge_modules')).to eq({})
        expect(subject.fixtures('repositories')).to eq({})
      end
    end
    context 'when file is empty' do
      it 'returns basic directories per category' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return false
        expect(subject.fixtures('forge_modules')).to eq({})
        expect(subject.fixtures('repositories')).to eq({})
      end
    end
    context 'when file is malformed' do
      it 'raises an error' do
        expect(File).to receive(:exist?).with('.fixtures.yml').and_return true
        expect(YAML).to receive(:load_file).with('.fixtures.yml').and_raise(Psych::SyntaxError.new('/file', '123', '0', '0', 'spec message', 'spec context'))
        expect { subject.fixtures('forge_modules') }.to raise_error(RuntimeError, %r{malformed YAML})
      end
    end
    context 'when file contains no fixtures' do
      it 'raises an error' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return('some' => 'key')
        expect { subject.fixtures('forge_modules') }.to raise_error(RuntimeError, %r{No 'fixtures'})
      end
    end
    context 'when file specifies fixtures' do
      it 'returns the hash' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return('fixtures' => { 'forge_modules' => { 'stdlib' => 'puppetlabs-stdlib' } })
        expect(subject.fixtures('forge_modules')).to eq('puppetlabs-stdlib' => {
                                                          'target' => 'spec/fixtures/modules/stdlib',
                                                          'ref'    => nil,
                                                          'branch' => nil,
                                                          'scm'    => nil,
                                                          'flags'  => nil,
                                                          'subdir' => nil,
                                                        })
      end
    end
    context 'when file specifies defaults' do
      it 'returns the hash' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return('defaults' => { 'forge_modules' => { 'flags' => '--module_repository=https://myforge.example.com/' } },
                                                                            'fixtures' => { 'forge_modules' => { 'stdlib' => 'puppetlabs-stdlib' } })
        expect(subject.fixtures('forge_modules')).to eq('puppetlabs-stdlib' => {
                                                          'target' => 'spec/fixtures/modules/stdlib',
                                                          'ref'    => nil,
                                                          'branch' => nil,
                                                          'scm'    => nil,
                                                          'flags'  => '--module_repository=https://myforge.example.com/',
                                                          'subdir' => nil,
                                                        })
      end
    end
  end
end
