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
    context 'when file specifies puppet version' do
      def stub_fixtures(data)
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return(data)
      end

      it 'includes the fixture if the puppet version matches', if: Gem::Version.new(Puppet::PUPPETVERSION) > Gem::Version.new('4') do
        stub_fixtures(
          'fixtures' => {
            'forge_modules' => {
              'stdlib' => {
                'repo' => 'puppetlabs-stdlib',
                'puppet_version' => Puppet::PUPPETVERSION,
              },
            },
          },
        )
        expect(subject.fixtures('forge_modules')).to include('puppetlabs-stdlib')
      end

      it 'excludes the fixture if the puppet version does not match', if: Gem::Version.new(Puppet::PUPPETVERSION) > Gem::Version.new('4') do
        stub_fixtures(
          'fixtures' => {
            'forge_modules' => {
              'stdlib' => {
                'repo' => 'puppetlabs-stdlib',
                'puppet_version' => '>= 999.9.9',
              },
            },
          },
        )
        expect(subject.fixtures('forge_modules')).to eq({})
      end

      it 'includes the fixture on obsolete puppet versions', if: Gem::Version.new(Puppet::PUPPETVERSION) <= Gem::Version.new('4') do
        stub_fixtures(
          'fixtures' => {
            'forge_modules' => {
              'stdlib' => {
                'repo' => 'puppetlabs-stdlib',
                'puppet_version' => Puppet::PUPPETVERSION,
              },
            },
          },
        )
        expect(subject.fixtures('forge_modules')).to include('puppetlabs-stdlib')
      end
    end
  end
end
