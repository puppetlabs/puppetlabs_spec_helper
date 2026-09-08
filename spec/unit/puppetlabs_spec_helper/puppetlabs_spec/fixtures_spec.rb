# frozen_string_literal: true

require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec_helper'

RSpec.describe PuppetlabsSpec::Fixtures do
  # fixture_helpers_spec.rb's describe '.fixtures' before block undefs all
  # PuppetlabsSpec::Fixtures methods. Reload before each example to restore them.
  around do |example|
    load File.expand_path('../../../../../lib/puppetlabs_spec_helper/puppetlabs_spec/fixtures.rb', __FILE__)
    example.run
  end

  # Use an isolated object to avoid method-resolution conflicts with
  # PuppetlabsSpecHelper::Tasks::FixtureHelpers#fixtures (also available on Object).
  subject(:obj) { Object.new.extend(described_class) }

  let(:fixture_dir) { PuppetlabsSpec::FIXTURE_DIR }

  describe '#fixtures' do
    it 'returns a path joined under FIXTURE_DIR' do
      expect(obj.fixtures('modules', 'stdlib')).to eq(File.join(fixture_dir, 'modules', 'stdlib'))
    end

    it 'returns FIXTURE_DIR itself with no extra segments' do
      expect(obj.fixtures).to eq(fixture_dir)
    end
  end

  describe '#my_fixture_dir' do
    it 'returns a path derived from this spec file under FIXTURE_DIR' do
      result = obj.my_fixture_dir
      expect(result).to start_with(fixture_dir)
    end

    it 'raises when the caller stack has no spec file' do
      allow(obj).to receive(:caller).and_return(['some/regular/file.rb:10'])
      expect { obj.my_fixture_dir }.to raise_error(/couldn't work out/)
    end
  end

  describe '#my_fixture' do
    let(:dir) { obj.my_fixture_dir }

    around do |example|
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'test.json'), '{}')
      example.run
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'returns the path to a readable fixture file' do
      expect(obj.my_fixture('test.json')).to eq(File.join(dir, 'test.json'))
    end

    it 'raises when the fixture file does not exist' do
      expect { obj.my_fixture('missing.json') }.to raise_error(/is not readable/)
    end
  end

  describe '#my_fixture_read' do
    let(:dir) { obj.my_fixture_dir }

    around do |example|
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'data.txt'), 'hello')
      example.run
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'returns the contents of the fixture file' do
      expect(obj.my_fixture_read('data.txt')).to eq('hello')
    end
  end

  describe '#my_fixtures' do
    let(:dir) { obj.my_fixture_dir }

    around do |example|
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'a.json'), '{}')
      File.write(File.join(dir, 'b.json'), '{}')
      example.run
    ensure
      FileUtils.rm_rf(dir)
    end

    it 'returns all files matching the glob' do
      expect(obj.my_fixtures('*.json').size).to eq(2)
    end

    it 'yields each matching file to a block' do
      yielded = []
      obj.my_fixtures('*.json') { |f| yielded << f }
      expect(yielded.size).to eq(2)
    end

    it 'raises an error when no files match the glob' do
      expect { obj.my_fixtures('*.xml') }.to raise_error(/had no files/)
    end
  end
end
