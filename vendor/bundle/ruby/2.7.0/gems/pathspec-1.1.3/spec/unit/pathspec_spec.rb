require 'spec_helper'
require 'fakefs/safe'
require 'pathspec'
require 'fakefs/spec_helpers'

describe PathSpec do
  shared_examples 'standard gitignore negation' do
    it { is_expected.not_to match('important.txt') }
    it { is_expected.not_to match('abc/important.txt') }
    it { is_expected.to match('bar/baz/') }
    it { is_expected.to match('foo/file') }
    it { is_expected.not_to match('foo/important.txt') }
    it { is_expected.to match('foo/subdir/file') }
  end

  # Specs that should be kept up to date with the README
  context 'README.md' do
    subject { PathSpec.from_filename 'spec/files/gitignore_readme' }

    it { is_expected.to match('abc/def.rb') }
    it { is_expected.not_to match('abc/important.txt') }
    it do
      expect(subject.match_paths(['/abc/123', '/abc/important.txt', '/abc/'])).to contain_exactly(
        '/abc/123',
        '/abc/'
      )
    end
  end

  context 'initialization' do
    context 'from multilines' do
      context '#new' do
        subject {
          PathSpec.new <<-IGNORELINES
!important.txt
foo/**
/bar/baz
IGNORELINES
        }

        it_behaves_like 'standard gitignore negation'
      end
    end

    context 'from a string with no newlines' do
      let(:str) { 'foo/**' }

      context '#new' do
        subject { PathSpec.new str }

        it { is_expected.to match('foo/important.txt') }
        it { is_expected.to match('foo/bar/') }
      end
    end

    context 'from a non-string/non-enumerable' do
      it 'throws an exception' do
        expect { PathSpec.new Object.new }.to raise_error(/Cannot make Pathspec/)
      end
    end

    context 'from array of gitignore strings' do
      let(:arr) { ['!important.txt', 'foo/**', '/bar/baz'] }

      context '#new' do
        subject { PathSpec.new arr }

        it_behaves_like 'standard gitignore negation'
      end

      context '#from_lines' do
        subject {
          PathSpec.from_lines(arr)
        }

        it_behaves_like 'standard gitignore negation'
      end

      context '#add array' do
        subject {
          ps = PathSpec.new []
          ps.add arr
        }

        it_behaves_like 'standard gitignore negation'
      end
    end

    context 'from linedelimited gitignore string' do
      let(:line) { "!important.txt\nfoo/**\n/bar/baz\n" }

      context '#new' do
        subject { PathSpec.new line }

        it_behaves_like 'standard gitignore negation'
      end

      context '#from_lines' do
        subject {
          PathSpec.from_lines(line)
        }

        it_behaves_like 'standard gitignore negation'
      end

      context '#add' do
        subject {
          ps = PathSpec.new
          ps.add line
        }

        it_behaves_like 'standard gitignore negation'
      end
    end

    context 'from a gitignore file' do
      include FakeFS::SpecHelpers

      let(:filename) { '.gitignore' }
      before(:each) do
        file = File.open(filename, 'w') { |f|
          f << "!important.txt\n"
          f << "foo/**\n"
          f << "/bar/baz\n"
        }
      end

      context '#new' do
        subject {
          PathSpec.new File.open(filename, 'r')
        }

        it_behaves_like 'standard gitignore negation'
      end

      context '#from_filename' do
        subject {
          PathSpec.from_filename(filename)
        }

        it_behaves_like 'standard gitignore negation'
      end
    end

    context 'from multiple gitignore files' do
      include FakeFS::SpecHelpers

      let(:filenames) { ['.gitignore', '.otherignore'] }
      before(:each) do
        file = File.open('.gitignore', 'w') { |f|
          f << "!important.txt\n"
          f << "foo/**\n"
          f << "/bar/baz\n"
        }

        file = File.open('.otherignore', 'w') { |f|
          f << "ban*na\n"
          f << "!banana\n"
        }
      end

      context '#new' do
        subject {
          arr = filenames.collect { |f| File.open(f, 'r') }
          PathSpec.new arr
        }

        it_behaves_like 'standard gitignore negation'

        it { is_expected.to_not match('banana') }
        it { is_expected.to match('banananananana') }
      end

      context '#add' do
        subject {
          arr = filenames.collect { |f| File.open(f, 'r') }
          ps = PathSpec.new
          ps.add arr
        }

        it_behaves_like 'standard gitignore negation'

        it { is_expected.to_not match('banana') }
        it { is_expected.to match('banananananana') }
      end
    end
  end

  context '#match_tree' do
    include FakeFS::SpecHelpers

    context 'unix' do
      let(:root) {'/tmp/project'}
      let(:gitignore) {
        <<-GITIGNORE
  !**/important.txt
  abc/**
  GITIGNORE
      }

      before(:each) {
        FileUtils.mkdir_p root
        FileUtils.mkdir_p "#{root}/abc"
        FileUtils.touch "#{root}/abc/1"
        FileUtils.touch "#{root}/abc/2"
        FileUtils.touch "#{root}/abc/important.txt"
      }

      subject {
        PathSpec.new(gitignore).match_tree(root)
      }

      it { is_expected.to include "#{root}/abc".to_s }
      it { is_expected.to include "#{root}/abc/1".to_s }
      it { is_expected.not_to include "#{root}/abc/important.txt".to_s }
      it { is_expected.not_to include root.to_s.to_s }
    end

    context 'windows' do
      let(:root) {'C:/project'}
      let(:gitignore) {
        <<-GITIGNORE
  !**/important.txt
  abc/**
  GITIGNORE
      }

      before(:each) {
        FileUtils.mkdir_p root
        FileUtils.mkdir_p "#{root}/abc"
        FileUtils.touch "#{root}/abc/1"
        FileUtils.touch "#{root}/abc/2"
        FileUtils.touch "#{root}/abc/important.txt"
      }

      subject {
        PathSpec.new(gitignore).match_tree(root)
      }

      it { is_expected.to include "#{root}/abc".to_s }
      it { is_expected.to include "#{root}/abc/1".to_s }
      it { is_expected.not_to include "#{root}/abc/important.txt".to_s }
      it { is_expected.not_to include root.to_s.to_s }
    end
  end

  context '#match_paths' do
    let(:gitignore) {
      <<-GITIGNORE
!**/important.txt
/abc/**
GITIGNORE
    }

    context 'with no root arg' do
      subject { PathSpec.new(gitignore).match_paths(['/abc/important.txt', '/abc/', '/abc/1']) }

      it { is_expected.to include '/abc/' }
      it { is_expected.to include '/abc/1' }
      it { is_expected.not_to include '/abc/important.txt' }
    end

    context 'relative to non-root dir' do
      subject {
        PathSpec.new(gitignore).match_paths([
                                              '/def/abc/important.txt',
                                              '/def/abc/',
                                              '/def/abc/1'
                                            ], '/def') }

      it { is_expected.to include '/def/abc/' }
      it { is_expected.to include '/def/abc/1' }
      it { is_expected.not_to include '/def/abc/important.txt' }
    end

    context 'relative to windows drive letter' do
      subject {
        PathSpec.new(gitignore).match_paths([
                                              'C:/def/abc/important.txt',
                                              'C:/def/abc/',
                                              'C:/def/abc/1'
                                            ], 'C:/def/') }

      it { is_expected.to include 'C:/def/abc/' }
      it { is_expected.to include 'C:/def/abc/1' }
      it { is_expected.not_to include 'C:/def/abc/important.txt' }
    end
  end

  # Example to exclude everything except a specific directory foo/bar (note
  # the /* - without the slash, the wildcard would also exclude everything
  # within foo/bar): (from git-scm.com)
  context 'very specific gitignore' do
    let(:gitignore) {
      <<-GITIGNORE
# exclude everything except directory foo/bar
/*
!/foo
/foo/*
!/foo/bar
GITIGNORE
    }

    subject { PathSpec.new(gitignore) }

    it { is_expected.not_to match('foo/bar') }
    it { is_expected.to match('anything') }
    it { is_expected.to match('foo/otherthing') }
  end

  context '#empty' do
    let(:gitignore) {
      <<-GITIGNORE
# A comment
GITIGNORE
    }

    subject { PathSpec.new gitignore }

    it 'is empty when there are no valid lines' do
      expect(subject.empty?).to be true
    end
  end

  context 'regex file' do
    let(:regexfile) {
      <<-REGEX
ab*a
REGEX
    }

    subject { PathSpec.new regexfile, :regex}

    it 'matches the regex' do
      expect(subject.match('anna')).to be false
      expect(subject.match('abba')).to be true
    end

    context '#from_filename' do
      it 'forwards the type argument' do
        io = double

        expect(File).to receive(:open).and_yield(io)
        expect(PathSpec).to receive(:from_lines).with(io, :regex)

        PathSpec.from_filename '/some/file', :regex
      end

      it 'reads a simple regex file' do
        spec = PathSpec.from_filename 'spec/files/regex_simple', :regex

        expect(spec.match('artifact.md')).to be true
        expect(spec.match('code.rb')).to be false
      end

      it 'reads a simple gitignore file' do
        spec = PathSpec.from_filename 'spec/files/gitignore_simple', :git

        expect(spec.match('artifact.md')).to be true
        expect(spec.match('code.rb')).to be false
      end

      it 'reads an example ruby gitignore file' do
        spec = PathSpec.from_filename 'spec/files/gitignore_ruby', :git

        expect(spec.match('coverage/')).to be true
        expect(spec.match('coverage/index.html')).to be true
        expect(spec.match('pathspec-0.0.1.gem')).to be true
        expect(spec.match('lib/pathspec')).to be false
        expect(spec.match('Gemfile')).to be false
      end
    end
  end

  context 'unsuppored spec type' do
    let(:file) {
      <<-REGEX
This is some kind of nonsense.
REGEX
    }

    it 'does not allow an unknown spec type' do
      expect { PathSpec.new file, :foo}.to raise_error(/Unknown/)
    end
  end
end
