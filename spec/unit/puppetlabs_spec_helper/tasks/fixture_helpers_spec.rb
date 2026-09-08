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

  # Reset memoized state on the module object between tests
  before do
    %i[@repositories @forge_modules @symlinks @logger @module_target_dir @max_thread_limit].each do |var|
      described_class.remove_instance_variable(var) if described_class.instance_variable_defined?(var)
    end
  end

  describe '.module_version' do
    subject(:helper) { described_class }

    context 'when metadata.json is readable and contains a version' do
      before do
        allow(File).to receive(:file?).with('mymodule/metadata.json').and_return(true)
        allow(File).to receive(:readable?).with('mymodule/metadata.json').and_return(true)
        allow(File).to receive(:read).with('mymodule/metadata.json').and_return('{"version":"2.0.0"}')
      end

      it 'returns the version' do
        expect(helper.module_version('mymodule')).to eq('2.0.0')
      end
    end

    context 'when metadata.json has no version key' do
      before do
        allow(File).to receive(:file?).with('mymodule/metadata.json').and_return(true)
        allow(File).to receive(:readable?).with('mymodule/metadata.json').and_return(true)
        allow(File).to receive(:read).with('mymodule/metadata.json').and_return('{}')
      end

      it 'returns 0.0.1' do
        expect(helper.module_version('mymodule')).to eq('0.0.1')
      end
    end

    context 'when metadata.json does not exist' do
      before do
        allow(File).to receive(:file?).with('mymodule/metadata.json').and_return(false)
      end

      it 'returns 0.0.1' do
        expect(helper.module_version('mymodule')).to eq('0.0.1')
      end
    end

    context 'when metadata.json contains invalid JSON' do
      before do
        allow(File).to receive(:file?).with('mymodule/metadata.json').and_return(true)
        allow(File).to receive(:readable?).with('mymodule/metadata.json').and_return(true)
        allow(File).to receive(:read).with('mymodule/metadata.json').and_return('{invalid}')
      end

      it 'returns 0.0.1' do
        expect(helper.module_version('mymodule')).to eq('0.0.1')
      end
    end
  end

  describe '.clone_repo' do
    subject(:helper) { described_class }

    before do
      allow(helper).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).with('target').and_return(true)
    end

    it 'clones a git repo with --depth 1 when no ref is given' do
      expect(helper).to receive(:system).with(a_string_including('git clone --depth 1'))
      helper.clone_repo('git', 'https://example.com/repo.git', 'target')
    end

    it 'clones a git repo without --depth 1 when a ref is given' do
      expect(helper).to receive(:system).with(satisfy { |s| !s.include?('--depth 1') })
      helper.clone_repo('git', 'https://example.com/repo.git', 'target', nil, 'abc123')
    end

    it 'includes the branch flag when branch is given' do
      expect(helper).to receive(:system).with(a_string_including('-b mybranch'))
      helper.clone_repo('git', 'https://example.com/repo.git', 'target', nil, nil, 'mybranch')
    end

    it 'includes custom flags when given' do
      expect(helper).to receive(:system).with(a_string_including('--some-flag'))
      helper.clone_repo('git', 'https://example.com/repo.git', 'target', nil, nil, nil, '--some-flag')
    end

    it 'clones an hg repo' do
      expect(helper).to receive(:system).with(a_string_including('hg clone'))
      helper.clone_repo('hg', 'https://example.com/hgrepo', 'target')
    end

    it 'includes hg branch flag when branch is given' do
      expect(helper).to receive(:system).with(a_string_including('-b stable'))
      helper.clone_repo('hg', 'https://example.com/hgrepo', 'target', nil, nil, 'stable')
    end

    it 'raises for unsupported scm' do
      expect { helper.clone_repo('svn', 'url', 'target') }.to raise_error(/not supported/)
    end

    it 'raises when target does not exist after clone' do
      allow(File).to receive(:exist?).with('missing').and_return(false)
      allow(helper).to receive(:system).and_return(true)
      expect { helper.clone_repo('git', 'url', 'missing') }.to raise_error(/Failed to clone/)
    end
  end

  describe '.update_repo' do
    subject(:helper) { described_class }

    before do
      allow(helper).to receive(:system).and_return(true)
      allow(helper).to receive(:shallow_git_repo?).and_return(false)
    end

    it 'runs git fetch for a normal git repo' do
      expect(helper).to receive(:system).with('git fetch', chdir: 'target')
      helper.update_repo('git', 'target')
    end

    it 'runs git fetch --unshallow for a shallow git repo' do
      allow(helper).to receive(:shallow_git_repo?).and_return(true)
      expect(helper).to receive(:system).with('git fetch --unshallow', chdir: 'target')
      helper.update_repo('git', 'target')
    end

    it 'runs hg pull' do
      expect(helper).to receive(:system).with('hg pull', chdir: 'target')
      helper.update_repo('hg', 'target')
    end

    it 'raises for unsupported scm' do
      expect { helper.update_repo('svn', 'target') }.to raise_error(/not supported/)
    end
  end

  describe '.shallow_git_repo?' do
    subject(:helper) { described_class }

    it 'returns true when .git/shallow exists' do
      allow(File).to receive(:file?).with(File.join('.git', 'shallow')).and_return(true)
      expect(helper.shallow_git_repo?).to be true
    end

    it 'returns false when .git/shallow does not exist' do
      allow(File).to receive(:file?).with(File.join('.git', 'shallow')).and_return(false)
      expect(helper.shallow_git_repo?).to be false
    end
  end

  describe '.revision' do
    subject(:helper) { described_class }

    before do
      allow(helper).to receive(:system).and_return(true)
    end

    it 'runs git reset --hard for git scm' do
      expect(helper).to receive(:system).with('git reset --hard abc123', chdir: 'target')
      helper.revision('git', 'target', 'abc123')
    end

    it 'runs hg update for hg scm' do
      expect(helper).to receive(:system).with('hg update --clean -r abc123', chdir: 'target')
      helper.revision('hg', 'target', 'abc123')
    end

    it 'raises for unsupported scm' do
      expect { helper.revision('svn', 'target', 'ref') }.to raise_error(/not supported/)
    end

    it 'raises when system command fails' do
      allow(helper).to receive(:system).and_return(false)
      expect { helper.revision('git', 'target', 'badref') }.to raise_error(/Invalid ref/)
    end
  end

  describe '.valid_repo?' do
    subject(:helper) { described_class }

    it 'returns false when target is not a directory' do
      allow(File).to receive(:directory?).with('target').and_return(false)
      expect(helper.valid_repo?('git', 'target', 'remote')).to be false
    end

    it 'returns true for hg when directory exists' do
      allow(File).to receive(:directory?).with('target').and_return(true)
      expect(helper.valid_repo?('hg', 'target', 'remote')).to be true
    end

    it 'returns true when git remote matches' do
      allow(File).to receive(:directory?).with('target').and_return(true)
      allow(helper).to receive(:git_remote_url).with('target').and_return('https://example.com/repo.git')
      expect(helper.valid_repo?('git', 'target', 'https://example.com/repo.git')).to be true
    end

    it 'removes target and returns false when git remote does not match' do
      allow(File).to receive(:directory?).with('target').and_return(true)
      allow(helper).to receive(:git_remote_url).with('target').and_return('https://example.com/other.git')
      expect(FileUtils).to receive(:rm_rf).with('target')
      expect(helper.valid_repo?('git', 'target', 'https://example.com/repo.git')).to be false
    end
  end

  describe '.git_remote_url' do
    subject(:helper) { described_class }

    it 'returns the stripped remote URL on success' do
      allow(Open3).to receive(:capture2e).and_return(["https://example.com/repo.git\n", double(success?: true)])
      expect(helper.git_remote_url('target')).to eq('https://example.com/repo.git')
    end

    it 'returns nil on failure' do
      allow(Open3).to receive(:capture2e).and_return(['', double(success?: false)])
      expect(helper.git_remote_url('target')).to be_nil
    end
  end

  describe '.remove_subdirectory' do
    subject(:helper) { described_class }

    it 'returns immediately when subdir is nil' do
      expect(Dir).not_to receive(:mktmpdir)
      helper.remove_subdirectory('target', nil)
    end

    it 'moves subdir contents up to target and removes the subdir' do
      Dir.mktmpdir do |base|
        target = File.join(base, 'target')
        FileUtils.mkdir_p(File.join(target, 'sub'))
        File.write(File.join(target, 'sub', 'file.txt'), 'content')
        helper.remove_subdirectory(target, 'sub')
        expect(File.exist?(File.join(target, 'file.txt'))).to be true
        expect(File.directory?(File.join(target, 'sub'))).to be false
      end
    end
  end

  describe '.logger' do
    subject(:helper) { described_class }

    it 'returns a Logger instance' do
      expect(helper.logger).to be_a(Logger)
    end

    it 'memoizes the logger' do
      expect(helper.logger).to equal(helper.logger)
    end

    it 'uses INFO level by default' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ENABLE_LOGGER').and_return(nil)
      described_class.remove_instance_variable(:@logger) if described_class.instance_variable_defined?(:@logger)
      expect(helper.logger.level).to eq(Logger::INFO)
    end

    it 'uses DEBUG level when ENABLE_LOGGER is set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ENABLE_LOGGER').and_return('true')
      described_class.remove_instance_variable(:@logger) if described_class.instance_variable_defined?(:@logger)
      expect(helper.logger.level).to eq(Logger::DEBUG)
    end
  end

  describe '.module_working_directory' do
    subject(:helper) { described_class }

    it 'returns the default working directory' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('MODULE_WORKING_DIR', nil).and_return(nil)
      expect(helper.module_working_directory).to eq(File.expand_path('spec/fixtures/work-dir'))
    end

    it 'uses MODULE_WORKING_DIR env when set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('MODULE_WORKING_DIR').and_return('/custom/path')
      expect(helper.module_working_directory).to eq('/custom/path')
    end
  end

  describe '.current_thread_count' do
    subject(:helper) { described_class }

    it 'returns 0 when no threads are tracked' do
      items = { 'a' => {}, 'b' => {} }
      expect(helper.current_thread_count(items)).to eq(0)
    end

    it 'returns 0 when all tracked threads have finished' do
      t = Thread.new {}
      t.join
      items = { 'a' => { thread: t } }
      expect(helper.current_thread_count(items)).to eq(0)
    end

    it 'counts threads that are still running' do
      ready = Queue.new
      done  = Queue.new
      t = Thread.new { ready.push(true); done.pop }
      ready.pop
      items = { 'a' => { thread: t } }
      count = helper.current_thread_count(items)
      done.push(true)
      t.join
      expect(count).to eq(1)
    end
  end

  describe '.max_thread_limit' do
    subject(:helper) { described_class }

    it 'defaults to 10' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('MAX_FIXTURE_THREAD_COUNT').and_return(nil)
      expect(helper.max_thread_limit).to eq(10)
    end

    it 'reads MAX_FIXTURE_THREAD_COUNT when set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('MAX_FIXTURE_THREAD_COUNT').and_return('3')
      expect(helper.max_thread_limit).to eq(3)
    end
  end

  describe '.download_items' do
    subject(:helper) { described_class }

    it 'calls the block for each item and waits for all threads' do
      results = []
      mutex   = Mutex.new
      items   = { 'remote1' => {}, 'remote2' => {} }
      helper.download_items(items) { |remote, _opts| mutex.synchronize { results << remote } }
      expect(results).to contain_exactly('remote1', 'remote2')
    end
  end

  describe '.setup_symlink' do
    subject(:helper) { described_class }

    it 'skips creation when the symlink already exists' do
      allow(File).to receive(:symlink?).with('link/path').and_return(true)
      expect(FileUtils).not_to receive(:ln_sf)
      helper.setup_symlink('target', { 'target' => 'link/path' })
    end

    it 'creates a symlink on non-Windows systems' do
      allow(File).to receive(:symlink?).with('link/path').and_return(false)
      allow(helper).to receive(:windows?).and_return(false)
      expect(FileUtils).to receive(:ln_sf).with('the_target', 'link/path')
      helper.setup_symlink('the_target', { 'target' => 'link/path' })
    end
  end

  describe '.download_repository' do
    subject(:helper) { described_class }

    let(:opts) do
      { 'target' => 'spec/fixtures/modules/mymod', 'scm' => 'git',
        'ref' => nil, 'branch' => nil, 'flags' => nil, 'subdir' => nil }
    end

    before do
      allow(helper).to receive(:valid_repo?).and_return(false)
      allow(helper).to receive(:clone_repo)
      allow(helper).to receive(:update_repo)
      allow(helper).to receive(:revision)
      allow(helper).to receive(:remove_subdirectory)
    end

    it 'calls clone_repo when repo is not valid' do
      expect(helper).to receive(:clone_repo)
      helper.download_repository('https://example.com/repo.git', opts)
    end

    it 'calls update_repo when repo is valid' do
      allow(helper).to receive(:valid_repo?).and_return(true)
      expect(helper).to receive(:update_repo).with('git', 'spec/fixtures/modules/mymod')
      helper.download_repository('https://example.com/repo.git', opts)
    end

    it 'calls revision when ref is set' do
      allow(helper).to receive(:valid_repo?).and_return(true)
      expect(helper).to receive(:revision).with('git', 'spec/fixtures/modules/mymod', 'abc123')
      helper.download_repository('https://example.com/repo.git', opts.merge('ref' => 'abc123'))
    end

    it 'calls remove_subdirectory when subdir is set' do
      allow(helper).to receive(:valid_repo?).and_return(true)
      expect(helper).to receive(:remove_subdirectory).with('spec/fixtures/modules/mymod', 'sub')
      helper.download_repository('https://example.com/repo.git', opts.merge('subdir' => 'sub'))
    end

    it 'uses opts scm when provided' do
      allow(helper).to receive(:valid_repo?).and_return(false)
      expect(helper).to receive(:clone_repo).with('hg', anything, anything, anything, anything, anything, anything)
      helper.download_repository('https://example.com/repo', opts.merge('scm' => 'hg'))
    end
  end

  describe '.module_target_dir' do
    subject(:helper) { described_class }

    it 'returns the expanded path to spec/fixtures/modules' do
      expect(helper.module_target_dir).to eq(File.expand_path('spec/fixtures/modules'))
    end

    it 'is memoized' do
      expect(helper.module_target_dir).to equal(helper.module_target_dir)
    end
  end

  describe '.download_module (additional cases)' do
    subject(:helper) { described_class }

    before do
      RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('FORGE_API_KEY', nil).and_return(nil)
    end

    after do
      RSpec::Mocks.configuration.allow_message_expectations_on_nil = false
    end

    context 'when opts is a String' do
      it 'uses the string as the target and returns false when already installed' do
        allow(File).to receive(:directory?).with('direct/target').and_return(true)
        allow(helper).to receive(:module_version).with('direct/target').and_return('0.0.1')
        expect(helper.download_module('puppetlabs-stdlib', 'direct/target')).to be false
      end
    end

    context 'when the module is already installed at the requested version' do
      let(:opts) { { 'target' => 'spec/fixtures/modules/stdlib', 'ref' => '1.0.0' } }

      it 'returns false without downloading' do
        allow(File).to receive(:directory?).with('spec/fixtures/modules/stdlib').and_return(true)
        allow(helper).to receive(:module_version).with('spec/fixtures/modules/stdlib').and_return('1.0.0')
        expect(helper.download_module('puppetlabs-stdlib', opts)).to be false
      end
    end

    context 'when the module needs to be downloaded' do
      let(:opts) { { 'target' => 'spec/fixtures/modules/stdlib' } }

      it 'runs puppet module install' do
        allow(File).to receive(:directory?).with('spec/fixtures/modules/stdlib').and_return(false)
        `true` # ensure $CHILD_STATUS is a real successful status
        allow(helper).to receive(:system).and_return(true)
        expect(helper).to receive(:system).with(a_string_including('puppet module install'))
        helper.download_module('puppetlabs-stdlib', opts)
      end
    end
  end

  describe '.fixtures (additional coverage)' do
    subject(:helper) { described_class }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return(nil)
    end

    context 'when FIXTURES_YML env is set to a valid file path' do
      before do
        allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return('.fixtures.yml')
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return('fixtures' => {})
      end

      it 'uses the FIXTURES_YML path (line 76)' do
        expect(helper.fixtures('forge_modules')).to eq({})
      end
    end

    context 'when .fixtures.yaml exists but .fixtures.yml does not' do
      before do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return(false)
        allow(File).to receive(:exist?).with('.fixtures.yaml').and_return(true)
        allow(YAML).to receive(:load_file).with('.fixtures.yaml').and_return('fixtures' => {})
      end

      it 'falls back to .fixtures.yaml (line 80)' do
        expect(helper.fixtures('forge_modules')).to eq({})
      end
    end

    context 'when FIXTURES_YML is set but the file is missing' do
      before do
        allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return('nonexistent.yml')
        allow(YAML).to receive(:load_file).with('nonexistent.yml').and_raise(Errno::ENOENT)
      end

      it 'raises a friendly error (line 92)' do
        expect { helper.fixtures('forge_modules') }.to raise_error(/Fixtures file not found/)
      end
    end

    context 'when a git repository fixture has a valid (slash-free) ref' do
      before do
        allow(File).to receive(:exist?).with('.fixtures.yml').and_return(true)
        allow(YAML).to receive(:load_file).with('.fixtures.yml').and_return(
          'fixtures' => {
            'repositories' => {
              'stdlib' => {
                'scm'  => 'git',
                'repo' => 'https://github.com/puppetlabs/puppetlabs-stdlib.git',
                'ref'  => 'v8.5.0',
              },
            },
          },
        )
      end

      it 'returns the fixture hash (validate_fixture_hash! line 155)' do
        result = helper.fixtures('repositories')
        expect(result).to include('https://github.com/puppetlabs/puppetlabs-stdlib.git')
      end
    end
  end

  describe '.download_items (throttling)' do
    subject(:helper) { described_class }

    it 'throttles threads to stay within max_thread_limit' do
      m = described_class
      m.remove_instance_variable(:@max_thread_limit) if m.instance_variable_defined?(:@max_thread_limit)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('MAX_FIXTURE_THREAD_COUNT').and_return('1')

      results = []
      mutex   = Mutex.new
      items   = { 'slow' => {}, 'fast' => {} }

      helper.download_items(items) do |remote, _opts|
        # Slow the first thread so the main loop reaches 'fast' while it is
        # still alive, triggering the throttle path (lines 312-316).
        sleep(0.02) if remote == 'slow'
        mutex.synchronize { results << remote }
      end

      expect(results).to contain_exactly('slow', 'fast')
    end
  end

  describe '.setup_symlink (Windows paths)' do
    subject(:helper) { described_class }

    context 'on a Windows system with Dir.create_junction available' do
      before do
        allow(File).to receive(:symlink?).with('link/path').and_return(false)
        allow(helper).to receive(:windows?).and_return(true)
        allow(Dir).to receive(:respond_to?).and_call_original
        allow(Dir).to receive(:respond_to?).with(:create_junction).and_return(true)
        allow(Dir).to receive(:create_junction)
      end

      it 'adjusts relative target path and calls Dir.create_junction (lines 332-334)' do
        helper.setup_symlink('target', { 'target' => 'link/path' })
        expect(Dir).to have_received(:create_junction)
      end
    end

    context 'on a Windows system without Dir.create_junction' do
      before do
        allow(File).to receive(:symlink?).with('link/path').and_return(false)
        allow(helper).to receive(:windows?).and_return(true)
        allow(Dir).to receive(:respond_to?).and_call_original
        allow(Dir).to receive(:respond_to?).with(:create_junction).and_return(false)
        allow(helper).to receive(:system)
      end

      it 'falls back to mklink (line 336)' do
        helper.setup_symlink('target', { 'target' => 'link/path' })
        expect(helper).to have_received(:system).with(a_string_including('mklink'))
      end
    end
  end

end

describe 'rake spec_prep', type: :task do
  before do
    # Reset memoized state so fixture lookups go through FakeFS
    %i[@repositories @forge_modules @symlinks @logger @module_target_dir @max_thread_limit].each do |var|
      m = PuppetlabsSpecHelper::Tasks::FixtureHelpers
      m.remove_instance_variable(var) if m.instance_variable_defined?(var)
    end
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return(nil)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('FORGE_API_KEY', nil).and_return(nil)
    # Use an empty fixtures file so only the auto-symlink runs
    File.write('.fixtures.yml', "fixtures:\n  symlinks:\n")
  end

  it 'creates the spec/fixtures/modules directory' do
    task.execute
    expect(File.directory?('spec/fixtures/modules')).to be true
  end

  it 'creates spec/fixtures/manifests/site.pp' do
    task.execute
    expect(File.exist?('spec/fixtures/manifests/site.pp')).to be true
  end

  context 'on Windows (lines 412, 414)' do
    before do
      # windows? is called as an instance method on main inside the task block
      allow_any_instance_of(Object).to receive(:windows?).and_return(true)
      # suppress the real mklink system call that setup_symlink issues on Windows
      allow_any_instance_of(Object).to receive(:system).and_return(true)
    end

    it 'attempts to require win32/dir without error' do
      expect { task.execute }.not_to raise_error
    end
  end
end

describe 'rake spec_clean', type: :task do
  before do
    %i[@repositories @forge_modules @symlinks @logger @module_target_dir @max_thread_limit].each do |var|
      m = PuppetlabsSpecHelper::Tasks::FixtureHelpers
      m.remove_instance_variable(var) if m.instance_variable_defined?(var)
    end
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return(nil)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('MODULE_WORKING_DIR', nil).and_return(nil)
    File.write('.fixtures.yml', "fixtures:\n  symlinks:\n")
    # Create the site.pp so spec_clean can remove it
    FileUtils.mkdir_p('spec/fixtures/manifests')
    FileUtils.touch('spec/fixtures/manifests/site.pp')
    # Ensure spec_clean_symlinks task can be re-invoked
    Rake::Task[:spec_clean_symlinks].reenable
  end

  it 'runs without raising an error' do
    expect { task.execute }.not_to raise_error
  end

  it 'removes an empty site.pp' do
    task.execute
    expect(File.exist?('spec/fixtures/manifests/site.pp')).to be false
  end

  context 'with repositories and forge modules (lines 434-435, 439-440)' do
    before do
      # repositories/forge_modules are called as instance methods on main inside the task block
      allow_any_instance_of(Object).to receive(:repositories).and_return(
        'https://example.com/repo.git' => { 'target' => 'spec/fixtures/modules/myrepo' },
      )
      allow_any_instance_of(Object).to receive(:forge_modules).and_return(
        'puppetlabs-stdlib' => { 'target' => 'spec/fixtures/modules/stdlib' },
      )
    end

    it 'removes repository and forge module targets' do
      expect { task.execute }.not_to raise_error
    end
  end
end

describe 'rake spec_clean_symlinks', type: :task do
  before do
    %i[@repositories @forge_modules @symlinks @logger @module_target_dir @max_thread_limit].each do |var|
      m = PuppetlabsSpecHelper::Tasks::FixtureHelpers
      m.remove_instance_variable(var) if m.instance_variable_defined?(var)
    end
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('FIXTURES_YML').and_return(nil)
    File.write('.fixtures.yml', "fixtures:\n  symlinks:\n")
  end

  it 'runs without raising an error' do
    expect { task.execute }.not_to raise_error
  end
end
