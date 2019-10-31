require 'spec_helper'

describe 'rake module:inspect', type: :task, unless: puppet_3_or_older? do
  let(:manifest_dir) { File.join(Dir.pwd, 'manifests') }
  let(:no_results) { { 'host_class' => [], 'defined_type' => [] } }

  before(:each) do
    Dir.mkdir(manifest_dir)
  end

  context 'when there are no files' do
    it 'runs without raising an error' do
      expect { task.execute }.to output_json(no_results).to_stdout
    end
  end

  context 'when there are empty manifests' do
    before(:each) do
      File.open(File.join(manifest_dir, 'empty.pp'), 'w') { |fd| }
    end

    it 'runs without raising an error' do
      expect { task.execute }.to output_json(no_results).to_stdout
    end
  end

  context 'when there are manifests containing class and defined types' do
    before(:each) do
      File.open(File.join(manifest_dir, 'file1.pp'), 'w') do |fd|
        fd.puts "class thing::thing1(String $foo = 'bar') inherits thing::params {}"
      end

      File.open(File.join(manifest_dir, 'file2.pp'), 'w') do |fd|
        fd.puts 'class thing::thing2 {}'
      end

      File.open(File.join(manifest_dir, 'file3.pp'), 'w') do |fd|
        fd.puts 'define thing::thing3($bar) { }'
      end
    end

    it 'lists all the definitions in the output' do
      expected = {
        'host_class' => [
          {
            'file' => File.join(manifest_dir, 'file1.pp'),
            'name' => 'thing::thing1',
            'parameters' => ['foo'],
            'parent' => 'thing::params',
          },
          {
            'file' => File.join(manifest_dir, 'file2.pp'),
            'name' => 'thing::thing2',
            'parameters' => [],
            'parent' => nil,
          },
        ],
        'defined_type' => [
          {
            'file' => File.join(manifest_dir, 'file3.pp'),
            'name' => 'thing::thing3',
            'parameters' => ['bar'],
          },
        ],
      }

      expect { task.execute }.to output_json(expected).to_stdout
    end
  end
end
