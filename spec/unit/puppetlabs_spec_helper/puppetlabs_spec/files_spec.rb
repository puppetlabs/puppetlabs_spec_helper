# frozen_string_literal: true

require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/files'

RSpec.describe PuppetlabsSpec::Files do
  # Reset global tempfiles state around each example
  around do |example|
    saved = $global_tempfiles
    $global_tempfiles = []
    example.run
    $global_tempfiles = saved
  end

  describe '.in_tmp' do
    it 'returns true when path is inside the system tmpdir' do
      path = File.join(Dir.tmpdir, 'some', 'nested', 'file')
      expect(described_class.in_tmp(path)).to be true
    end

    it 'returns false when path is not inside the system tmpdir' do
      expect(described_class.in_tmp('/etc/passwd')).to be false
    end
  end

  describe '.cleanup' do
    it 'removes files recorded in $global_tempfiles' do
      path = Dir.mktmpdir
      $global_tempfiles = [path]
      described_class.cleanup
      expect(File.exist?(path)).to be false
    end

    it 'does not raise when a recorded path no longer exists' do
      $global_tempfiles = [File.join(Dir.tmpdir, "already_gone_#{rand}")]
      expect { described_class.cleanup }.not_to raise_error
    end

    it 'raises when a recorded path is outside tmpdir' do
      $global_tempfiles = ['/etc/some_file']
      expect { described_class.cleanup }.to raise_error(/Not deleting tmpfile/)
    end
  end

  describe '#tmpfilename' do
    include described_class

    it 'returns a path string' do
      expect(tmpfilename('test')).to be_a(String)
    end

    it 'records the path in $global_tempfiles' do
      path = tmpfilename('test')
      expect($global_tempfiles).to include(File.expand_path(path))
    end

    it 'returns a path that does not exist (file is deleted after name generation)' do
      path = tmpfilename('test')
      expect(File.exist?(path)).to be false
    end
  end

  describe '#tmpdir' do
    include described_class

    it 'returns a path to an existing directory' do
      path = tmpdir('testdir')
      expect(File.directory?(path)).to be true
    end

    it 'records the path in $global_tempfiles' do
      path = tmpdir('testdir')
      expect($global_tempfiles).to include(File.expand_path(path))
    end
  end

  describe '#make_absolute' do
    include described_class

    it 'expands a relative path to an absolute path' do
      result = make_absolute('some/relative/path')
      expect(result).to eq(File.expand_path('some/relative/path'))
    end
  end
end
