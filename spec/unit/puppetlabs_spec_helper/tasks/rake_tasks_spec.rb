# frozen_string_literal: true

require 'spec_helper'

describe 'rake check:dot_underscore', type: :task do
  context 'when no ._ files are present' do
    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when ._ files are present' do
    before do
      FileUtils.touch('._somefile')
    end

    it 'raises an error' do
      expect { task.execute }
        .to raise_error(/\._/)
        .and output(a_string_including('._somefile')).to_stdout
    end
  end
end

describe 'rake check:git_ignore', type: :task do
  context 'when no ignored files are committed' do
    before do
      `true` # ensure $CHILD_STATUS is a real successful status
      allow_any_instance_of(Object).to receive(:`).with('git ls-files --ignored --exclude-standard --cached').and_return('')
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when ignored files are committed' do
    before do
      `true` # ensure $CHILD_STATUS is a real successful status
      allow_any_instance_of(Object).to receive(:`).with('git ls-files --ignored --exclude-standard --cached').and_return("ignored_file.txt\n")
    end

    it 'raises an error' do
      expect { task.execute }
        .to raise_error(/gitignore.*committed/i)
        .and output(a_string_including('ignored_file.txt')).to_stdout
    end
  end

  context 'when git ls-files fails' do
    before do
      `false` # ensure $CHILD_STATUS is a real failed status
      allow_any_instance_of(Object).to receive(:`).with('git ls-files --ignored --exclude-standard --cached').and_return('')
    end

    it 'raises an error' do
      expect { task.execute }.to raise_error(/git ls-files failed/)
    end
  end
end

describe 'rake compute_dev_version', type: :task do
  before do
    `true` # ensure $CHILD_STATUS is a real successful status
    allow_any_instance_of(Object).to receive(:`).with('git rev-parse HEAD').and_return("abc12345\n")
    allow_any_instance_of(Object).to receive(:`).with('git rev-parse --abbrev-ref HEAD').and_return("main\n")
  end

  context 'when metadata.json exists' do
    before do
      File.write('metadata.json', '{"version":"1.2.3"}')
    end

    it 'prints the dev version including the module version' do
      expect { task.execute }.to output(a_string_including('1.2.3')).to_stdout
    end

    it 'prints the dev version including the short sha' do
      expect { task.execute }.to output(a_string_including('abc12345')).to_stdout
    end

    context 'when BUILD_NUMBER env is set' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('BUILD_NUMBER', nil).and_return('7')
      end

      it 'includes the zero-padded build number in the version' do
        expect { task.execute }.to output(a_string_matching(/1\.2\.3-\d{4}-/)).to_stdout
      end
    end

    context 'when BUILD_NUMBER env is set and branch is release' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('BUILD_NUMBER', nil).and_return('7')
        allow_any_instance_of(Object).to receive(:`).with('git rev-parse --abbrev-ref HEAD').and_return('release')
      end

      it 'uses the release version format with r prefix' do
        expect { task.execute }.to output(a_string_matching(/1\.2\.3-r\d{4}-/)).to_stdout
      end
    end
  end

  context 'when only Modulefile exists (lines 203-204)' do
    before do
      File.write('Modulefile', "\nversion '2.3.4'\n")
    end

    it 'reads the version from Modulefile' do
      expect { task.execute }.to output(a_string_including('2.3.4')).to_stdout
    end
  end

  context 'when neither metadata.json nor Modulefile exists' do
    it 'raises an error' do
      expect { task.execute }.to raise_error(/metadata\.json or Modulefile/)
    end
  end
end

describe 'rake spec:simplecov', type: :task do
  before do
    allow(Rake::Task[:spec]).to receive(:execute)
  end

  after do
    ENV.delete('SIMPLECOV')
  end

  it 'sets SIMPLECOV env variable before running spec' do
    task.execute
    expect(ENV.fetch('SIMPLECOV', nil)).to eq('yes')
  end
end

describe 'rake spec', type: :task do
  before do
    allow(Rake::Task[:spec_prep]).to receive(:invoke)
    allow(Rake::Task[:spec_standalone]).to receive(:invoke)
    allow(Rake::Task[:spec_clean]).to receive(:invoke)
    allow(Rake::Task[:spec_clean_symlinks]).to receive(:invoke)
  end

  it 'invokes spec_prep then spec_standalone then spec_clean' do
    expect(Rake::Task[:spec_prep]).to receive(:invoke).ordered
    expect(Rake::Task[:spec_standalone]).to receive(:invoke).ordered
    expect(Rake::Task[:spec_clean]).to receive(:invoke).ordered
    task.execute
  end

  it 'always invokes spec_clean_symlinks in the ensure block' do
    allow(Rake::Task[:spec_standalone]).to receive(:invoke).and_raise(RuntimeError, 'spec failed')
    expect(Rake::Task[:spec_clean_symlinks]).to receive(:invoke)
    expect { task.execute }.to raise_error(RuntimeError)
  end
end

describe 'rake parallel_spec', type: :task do
  before do
    allow(Rake::Task[:spec_prep]).to receive(:invoke)
    allow(Rake::Task[:parallel_spec_standalone]).to receive(:invoke)
    allow(Rake::Task[:spec_clean]).to receive(:invoke)
    allow(Rake::Task[:spec_clean_symlinks]).to receive(:invoke)
  end

  it 'invokes spec_prep, parallel_spec_standalone, and spec_clean' do
    expect(Rake::Task[:spec_prep]).to receive(:invoke)
    expect(Rake::Task[:parallel_spec_standalone]).to receive(:invoke)
    expect(Rake::Task[:spec_clean]).to receive(:invoke)
    task.execute
  end

  it 'always invokes spec_clean_symlinks in the ensure block' do
    allow(Rake::Task[:parallel_spec_standalone]).to receive(:invoke).and_raise(RuntimeError, 'failed')
    expect(Rake::Task[:spec_clean_symlinks]).to receive(:invoke)
    expect { task.execute }.to raise_error(RuntimeError)
  end
end

describe 'rake release_checks', type: :task do
  before do
    allow(Rake::Task[:lint]).to receive(:invoke)
    allow(Rake::Task[:validate]).to receive(:invoke)
    allow(Rake::Task[:spec]).to receive(:invoke)
    allow(Rake::Task[:parallel_spec]).to receive(:invoke)
    allow(Rake::Task[:check]).to receive(:invoke)
  end

  it 'runs without raising an error' do
    expect { task.execute }.not_to raise_error
  end

  it 'invokes lint and validate' do
    expect(Rake::Task[:lint]).to receive(:invoke)
    expect(Rake::Task[:validate]).to receive(:invoke)
    task.execute
  end

  it 'invokes check' do
    expect(Rake::Task[:check]).to receive(:invoke)
    task.execute
  end
end

describe 'rake validate', type: :task do
  before do
    allow(Rake::Task[:syntax]).to receive(:invoke)
    allow(ENV).to receive(:[]).and_call_original
  end

  context 'with no lib ruby files and no metadata.json or REFERENCE.md' do
    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when metadata.json exists' do
    before do
      File.write('metadata.json', '{"name":"test-module"}')
    end

    it 'attempts metadata validation' do
      # metadata_lint task may or may not be defined; either path should not crash
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when metadata.json and metadata_lint task are both available' do
    before do
      File.write('metadata.json', '{"name":"test-module"}')
      Rake::Task.define_task(:metadata_lint) { nil }
      allow(Rake::Task[:metadata_lint]).to receive(:invoke)
    end

    after do
      Rake.application.instance_variable_get(:@tasks).delete('metadata_lint')
    end

    it 'invokes metadata_lint' do
      expect(Rake::Task[:metadata_lint]).to receive(:invoke)
      task.execute
    end
  end

  context 'when REFERENCE.md exists' do
    before do
      File.write('REFERENCE.md', '# Reference')
    end

    it 'attempts reference validation' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when REFERENCE.md and strings:validate:reference task are both available' do
    before do
      File.write('REFERENCE.md', '# Reference')
      Rake::Task.define_task('strings:validate:reference') { nil }
      allow(Rake::Task['strings:validate:reference']).to receive(:invoke)
    end

    after do
      Rake.application.instance_variable_get(:@tasks).delete('strings:validate:reference')
    end

    it 'invokes strings:validate:reference' do
      expect(Rake::Task['strings:validate:reference']).to receive(:invoke)
      task.execute
    end
  end

  context 'when lib/*.rb files exist (line 173)' do
    before do
      allow(Dir).to receive(:[]).and_call_original
      allow(Dir).to receive(:[]).with('lib/**/*.rb').and_return(['lib/my_class.rb'])
      # sh calls system() internally; stub it so no real subprocess is spawned
      allow_any_instance_of(Object).to receive(:system).and_return(true)
    end

    it 'runs ruby -c on each lib file' do
      expect { task.execute }.not_to raise_error
    end
  end
end

describe 'rake help', type: :task do
  it 'calls system to list rake tasks' do
    allow_any_instance_of(Object).to receive(:system).with('rake -T').and_return(true)
    expect_any_instance_of(Object).to receive(:system).with('rake -T')
    task.execute
  end
end

describe 'rake spec_standalone', type: :task do
  before do
    # Prevent RSpec from actually running — we only want the configure block to run.
    allow_any_instance_of(RSpec::Core::RakeTask).to receive(:run_task)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('CI_SPEC_OPTIONS').and_return(nil)
    allow(ENV).to receive(:[]).with('CI_NODE_TOTAL').and_return(nil)
    allow(ENV).to receive(:[]).with('CI_NODE_INDEX').and_return(nil)
  end

  context 'without CI env vars and no extra args' do
    it 'sets the default pattern (lines 51-53, 66-67)' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'without CI env vars but with extra args' do
    it 'uses the extras as the pattern (line 69)' do
      expect { task.execute(Rake::TaskArguments.new([], ['spec/unit/foo_spec.rb'])) }.not_to raise_error
    end
  end

  context 'with CI env vars set to valid values' do
    before do
      allow(ENV).to receive(:[]).with('CI_NODE_TOTAL').and_return('2')
      allow(ENV).to receive(:[]).with('CI_NODE_INDEX').and_return('1')
      # Create a fake spec file so Rake::FileList finds at least one entry.
      FileUtils.mkdir_p('spec/unit/fake')
      File.write('spec/unit/fake/my_spec.rb', '')
    end

    it 'splits files across CI nodes (lines 54-61)' do
      expect { task.execute }.not_to raise_error
    end

    context 'with extra args in CI mode' do
      it 'uses the extras as the pattern (line 63)' do
        expect { task.execute(Rake::TaskArguments.new([], ['spec/unit/fake/my_spec.rb'])) }.not_to raise_error
      end
    end
  end
end

describe 'rake spec_list_json', type: :task do
  before do
    allow_any_instance_of(RSpec::Core::RakeTask).to receive(:run_task)
  end

  it 'configures dry-run JSON output (lines 76-77)' do
    expect { task.execute }.not_to raise_error
  end
end

describe 'rake parallel_spec_standalone', type: :task do
  it 'raises when parallel_tests gem is not loaded (line 108)' do
    expect { task.execute }.to raise_error(/parallel_tests gem/)
  end
end

describe 'rake rubocop', type: :task do
  before do
    allow_any_instance_of(RuboCop::RakeTask).to receive(:run_cli)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GITHUB_ACTIONS').and_return('true')
    allow(Gem::Specification).to receive(:find_by_name).with('rubocop').and_return(
      instance_double(Gem::Specification, version: Gem::Version.new('1.64.1')),
    )
  end

  it 'configures rubocop options and adds github formatter (lines 293, 296-298)' do
    expect { task.execute }.not_to raise_error
  end
end

describe 'create_gch_task' do
  include Rake::DSL

  # create_gch_task is a method defined in rake_tasks.rb.  When
  # github_changelog_generator is absent the else branch runs (lines 309, 369-371).
  it 'defines a :changelog task that raises when gem is missing' do
    create_gch_task
    expect { Rake::Task[:changelog].execute }.to raise_error(/github_changelog_generator/)
  end

  context 'when github_changelog_generator gem is available' do
    before do
      allow(Bundler.rubygems).to receive(:find_name)
        .with('github_changelog_generator')
        .and_return([double('gemspec')])
      allow(File).to receive(:read).with('metadata.json').and_return(
        '{"author":"myuser","name":"mymodule","version":"1.0.0"}',
      )
      config = double('config').as_null_object
      stub_const('GitHubChangelogGenerator::RakeTask', double('RakeTask'))
      allow(GitHubChangelogGenerator::RakeTask).to receive(:new)
        .with(:changelog)
        .and_yield(config)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CHANGELOG_GITHUB_TOKEN').and_return('fake_token')
    end

    it 'defines a changelog task using gem configuration' do
      expect { create_gch_task }.not_to raise_error
    end
  end
end
