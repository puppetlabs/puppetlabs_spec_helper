# frozen_string_literal: true

require 'spec_helper'
require 'puppetlabs_spec_helper/tasks/fixtures'

describe PuppetlabsSpecHelper::Tasks::FixtureHelpers do
  describe '.module_name' do
    subject(:module_name) { described_class.module_name }

    before do
      allow(Dir).to receive(:pwd).and_return(File.join('path', 'to', 'my-awsome-module_from_pwd'))
    end

    shared_examples 'module name from working directory' do
      it 'determines the module name from the working directory name' do
        expect(module_name).to eq('module_from_pwd')
      end
    end

    shared_examples 'module name from metadata' do
      it 'determines the module name from the module metadata' do
        expect(module_name).to eq('module_from_metadata')
      end
    end

    context 'when metadata.json does not exist' do
      before do
        allow(File).to receive(:file?).with('metadata.json').and_return(false)
      end

      it_behaves_like 'module name from working directory'
    end

    context 'when metadata.json does exist' do
      before do
        allow(File).to receive(:file?).with('metadata.json').and_return(true)
      end

      context 'when it is not readable' do
        before do
          allow(File).to receive(:readable?).with('metadata.json').and_return(false)
        end

        it_behaves_like 'module name from working directory'
      end

      context 'when it is readable' do
        before do
          allow(File).to receive(:readable?).with('metadata.json').and_return(true)
          allow(File).to receive(:read).with('metadata.json').and_return(metadata_content)
        end

        context 'when it contains invalid JSON' do
          let(:metadata_content) { '{ "name": "my-awesome-module_from_metadata", }' }

          it_behaves_like 'module name from working directory'
        end

        context 'when it contains a name value' do
          let(:metadata_content) { '{ "name": "my-awesome-module_from_metadata" }' }

          it_behaves_like 'module name from metadata'
        end

        context 'when it does not contain a name value' do
          let(:metadata_content) { '{}' }

          it_behaves_like 'module name from working directory'
        end

        context 'when the name has a null value' do
          let(:metadata_content) { '{ "name": null }' }

          it_behaves_like 'module name from working directory'
        end

        context 'when the name is blank' do
          let(:metadata_content) { '{ "name": "" }' }

          it_behaves_like 'module name from working directory'
        end
      end
    end
  end

  describe '.fixtures' do
    subject(:helper) { described_class }

    before do
      # Unstub the fixtures "helpers"
      PuppetlabsSpec::Fixtures.instance_methods.each do |m|
        PuppetlabsSpec::Fixtures.send(:undef_method, m)
      end
      allow(File).to receive(:exist?).with('.fixtures.yml').and_return false
      allow(File).to receive(:exist?).with('.fixtures.yaml').and_return false
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return(nil)
      allow(described_class).to receive(:auto_symlink).and_return('project' => source_dir.to_s)
    end

    context 'when file is missing' do
      it 'returns basic directories per category' do
        expect(helper.fixtures('forge_modules')).to eq({})
        expect(helper.fixtures('repositories')).to eq({})
      end
    end

    context 'when file is empty' do
      it 'returns basic directories per category' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return false
        expect(helper.fixtures('forge_modules')).to eq({})
        expect(helper.fixtures('repositories')).to eq({})
      end
    end

    context 'when file is malformed' do
      it 'raises an error' do
        expect(File).to receive(:exist?).with('.fixtures.yml').and_return true
        expect(YAML).to receive(:load_file).with('.fixtures.yml').and_raise(Psych::SyntaxError.new('/file', '123', '0', '0', 'spec message', 'spec context'))
        expect { helper.fixtures('forge_modules') }.to raise_error(RuntimeError, /malformed YAML/)
      end
    end

    context 'when file contains no fixtures' do
      it 'raises an error' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return('some' => 'key')
        expect { helper.fixtures('forge_modules') }.to raise_error(RuntimeError, /No 'fixtures'/)
      end
    end

    context 'when file specifies fixtures' do
      it 'returns the hash' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return('fixtures' => { 'forge_modules' => { 'stdlib' => 'puppetlabs-stdlib' } })
        expect(helper.fixtures('forge_modules')).to eq(
          'puppetlabs-stdlib' => {
            'target' => 'spec/fixtures/modules/stdlib',
            'ref' => nil,
            'branch' => nil,
            'scm' => nil,
            'flags' => nil,
            'subdir' => nil,
          },
        )
      end
    end

    context 'when file specifies defaults' do
      it 'returns the hash' do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return('defaults' => { 'forge_modules' => { 'flags' => '--module_repository=https://myforge.example.com/' } },
                                                                            'fixtures' => { 'forge_modules' => { 'stdlib' => 'puppetlabs-stdlib' } })
        expect(helper.fixtures('forge_modules')).to eq(
          'puppetlabs-stdlib' => {
            'target' => 'spec/fixtures/modules/stdlib',
            'ref' => nil,
            'branch' => nil,
            'scm' => nil,
            'flags' => '--module_repository=https://myforge.example.com/',
            'subdir' => nil,
          },
        )
      end
    end

    context 'when forge_api_key env variable is set' do
      before do
        # required to prevent unwanted output on stub of $CHILD_STATUS
        RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
      end

      after do
        RSpec::Mocks.configuration.allow_message_expectations_on_nil = false
      end

      it 'correctly sets --forge_authorization' do
        allow(ENV).to receive(:fetch).with('FORGE_API_KEY', nil).and_return('myforgeapikey')
        # Mock the system call to prevent actual execution
        allow_any_instance_of(Kernel).to receive(:system) do |command| # rubocop:disable RSpec/AnyInstance
          expect(command).to include('--forge_authorization "Bearer myforgeapikey"')
          # Simulate setting $CHILD_STATUS to a successful status
          allow($CHILD_STATUS).to receive(:success?).and_return(true)
          true
        end
        helper.download_module('puppetlabs-stdlib', 'target' => 'spec/fixtures/modules/stdlib')
      end
    end

    context 'when file specifies repository fixtures' do
      before do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return(
          'fixtures' => {
            'repositories' => { 'stdlib' => 'https://github.com/puppetlabs/puppetlabs-stdlib.git' },
          },
        )
      end

      it 'returns the hash' do
        expect(helper.repositories).to eq(
          'https://github.com/puppetlabs/puppetlabs-stdlib.git' => {
            'target' => 'spec/fixtures/modules/stdlib',
            'ref' => nil,
            'branch' => nil,
            'scm' => nil,
            'flags' => nil,
            'subdir' => nil,
          },
        )
      end
    end

    context 'when file specifies repository fixtures with an invalid git ref' do
      before do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return true
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return(
          'fixtures' => {
            'repositories' => {
              'stdlib' => {
                'scm' => 'git',
                'repo' => 'https://github.com/puppetlabs/puppetlabs-stdlib.git',
                'ref' => 'this/is/a/branch',
              },
            },
          },
        )
      end

      it 'raises an ArgumentError' do
        expect { helper.fixtures('repositories') }.to raise_error(ArgumentError)
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
        expect(helper.fixtures('forge_modules')).to include('puppetlabs-stdlib')
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
        expect(helper.fixtures('forge_modules')).to eq({})
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
        expect(helper.fixtures('forge_modules')).to include('puppetlabs-stdlib')
      end
    end
  end
end
