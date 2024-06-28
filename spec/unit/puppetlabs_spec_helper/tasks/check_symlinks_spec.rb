# frozen_string_literal: true

require 'spec_helper'

describe 'rake check:symlinks', type: :task do
  before do
    test_files.each do |f|
      FileUtils.mkdir_p(File.dirname(f))
      FileUtils.touch(f)
    end

    symlinks.each do |link, target|
      FileUtils.mkdir_p(File.dirname(link))
      FileUtils.ln_s(target, link)
    end
  end

  let(:test_files) { [] }
  let(:symlinks) { {} }
  let(:expected_output) do
    symlinks.map { |link, target| "Symlink found: #{link} => #{target}" }.join("\n")
  end

  context 'when there are no files' do
    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when there are regular files' do
    let(:test_files) do
      [
        File.join(Dir.pwd, 'files', 'a_file.pp'),
        File.join(Dir.pwd, 'files', 'another_file.pp'),
      ]
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when there is a symlink present' do
    let(:test_files) do
      [
        File.join(Dir.pwd, 'files', 'a_file.pp'),
      ]
    end

    let(:symlinks) do
      {
        File.join(Dir.pwd, 'files', 'a_symlink.pp') => File.join(Dir.pwd, 'files', 'a_file.pp'),
      }
    end

    it 'raises an error' do
      expect { task.execute }
        .to raise_error(/symlink\(s\) exist/i)
        .and output(a_string_including(expected_output)).to_stdout
    end
  end

  context 'when there are symlinks under .git/' do
    let(:test_files) do
      [
        File.join(Dir.pwd, 'files', 'a_file.pp'),
      ]
    end

    let(:symlinks) do
      {
        File.join(Dir.pwd, '.git', 'a_symlink.pp') => File.join(Dir.pwd, 'files', 'a_file.pp'),
      }
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when there are symlinks under .bundle/' do
    let(:test_files) do
      [
        File.join(Dir.pwd, 'files', 'a_file.pp'),
      ]
    end

    let(:symlinks) do
      {
        File.join(Dir.pwd, '.bundle', 'a_symlink.pp') => File.join(Dir.pwd, 'files', 'a_file.pp'),
      }
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when there are symlinks under vendor/' do
    let(:test_files) do
      [
        File.join(Dir.pwd, 'files', 'a_file.pp'),
      ]
    end

    let(:symlinks) do
      {
        File.join(Dir.pwd, 'vendor', 'a_symlink.pp') => File.join(Dir.pwd, 'files', 'a_file.pp'),
      }
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when there are symlinks under a directory listed in .gitignore' do
    before do
      File.write(File.join(Dir.pwd, '.gitignore'), "a_directory/\n")
    end

    let(:test_files) do
      [
        File.join(Dir.pwd, 'files', 'a_file.pp'),
      ]
    end

    let(:symlinks) do
      {
        File.join(Dir.pwd, 'a_directory', 'a_symlink.pp') => File.join(Dir.pwd, 'files', 'a_file.pp'),
      }
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end

  context 'when there are symlinks under a directory listed in .pdkignore' do
    before do
      File.open(File.join(Dir.pwd, '.pdkignore'), 'w') do |f|
        f.puts '/another_directory/'
      end
    end

    let(:test_files) do
      [
        File.join(Dir.pwd, 'files', 'a_file.pp'),
      ]
    end

    let(:symlinks) do
      {
        File.join(Dir.pwd, 'another_directory', 'a_symlink.pp') => File.join(Dir.pwd, 'files', 'a_file.pp'),
      }
    end

    it 'runs without raising an error' do
      expect { task.execute }.not_to raise_error
    end
  end
end
