# frozen_string_literal: true

require 'spec_helper'

describe 'rake check:test_file', type: :task do
  context 'when there are .pp files under tests/' do
    before do
      test_files.each do |f|
        FileUtils.mkdir_p(File.dirname(f))
        FileUtils.touch(f)
      end
    end

    let(:test_files) do
      [
        File.join(Dir.pwd, 'tests', 'an_example.pp'),
        File.join(Dir.pwd, 'tests', 'deep', 'directory', 'structure', 'another_example.pp'),
      ]
    end

    it 'raises an error' do
      expected_output = test_files.join("\n")

      expect { task.execute }
        .to raise_error(/pp files present in tests folder/)
        .and output(a_string_including(expected_output)).to_stdout
    end
  end

  context 'when there are no .pp files under tests/' do
    before do
      FileUtils.mkdir('tests')
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when there is no tests/ directory' do
    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end
end
