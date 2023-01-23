require 'spec_helper'
require 'pathspec/gitignorespec'

describe PathSpec::GitIgnoreSpec do
  # Original specification by http://git-scm.com/docs/gitignore

  # A blank line matches no files, so it can serve as a separator for
  # readability.
  describe 'does nothing for newlines' do
    subject { PathSpec::GitIgnoreSpec.new "\n" }
    it { is_expected.to_not match('foo.tmp') }
    it { is_expected.to_not match(' ') }
    it { is_expected.to_not be_inclusive }
  end

  describe 'does nothing for blank strings' do
    subject { PathSpec::GitIgnoreSpec.new '' }
    it { is_expected.to_not match 'foo.tmp' }
    it { is_expected.to_not match ' ' }
    it { is_expected.to_not be_inclusive }
  end

  # A line starting with # serves as a comment. Put a backslash ("\") in front
  # of the first hash for patterns that begin with a hash.
  describe 'does nothing for comments' do
    subject { PathSpec::GitIgnoreSpec.new '# this is a gitignore style comment' }
    it { is_expected.to_not match('foo.tmp') }
    it { is_expected.to_not match(' ') }
    it { is_expected.to_not be_inclusive }
  end

  describe 'ignores comment char with a slash' do
    subject { PathSpec::GitIgnoreSpec.new '\#averystrangefile' }
    it { is_expected.to match('#averystrangefile') }
    it { is_expected.to_not match('foobar') }
    it { is_expected.to be_inclusive }
  end

  describe 'escapes characters with slashes' do
    subject { PathSpec::GitIgnoreSpec.new 'twinkletwinkle\*' }
    it { is_expected.to match('twinkletwinkle*') }
    it { is_expected.to_not match('twinkletwinkletwinkle') }
    it { is_expected.to be_inclusive }
  end

  # Trailing spaces are ignored unless they are quoted with backlash ("\").
  describe 'ignores trailing spaces' do
    subject { PathSpec::GitIgnoreSpec.new 'foo        ' }
    it { is_expected.to match('foo') }
    it { is_expected.to_not match('foo        ') }
    it { is_expected.to be_inclusive }
  end

  # This is not handled properly yet
  describe 'does not ignore escaped trailing spaces'

  # An optional prefix "!" which negates the pattern; any matching file excluded
  # by a previous pattern will become included again. It is not possible to
  # re-include a file if a parent directory of that file is excluded. Git
  # doesn't list excluded directories for performance reasons, so any patterns
  # on contained files have no effect, no matter where they are defined. Put a
  # backslash ("\") in front of the first "!" for patterns that begin with a
  # literal "!", for example, "\!important!.txt".
  describe 'is exclusive of !' do
    subject { PathSpec::GitIgnoreSpec.new '!important.txt' }
    it { is_expected.to match('important.txt') }
    it { is_expected.to_not be_inclusive }
    it { is_expected.to_not match('!important.txt') }
  end

  # If the pattern ends with a slash, it is removed for the purpose of the
  # following description, but it would only find a match with a directory. In
  # other words, foo/ will match a directory foo and paths underneath it, but
  # will not match a regular file or a symbolic link foo (this is consistent
  # with the way how pathspec works in general in Git).
  describe 'trailing slashes match directories and their contents but not regular files or symlinks' do
    subject { PathSpec::GitIgnoreSpec.new 'foo/' }
    it { is_expected.to match('foo/') }
    it { is_expected.to match('foo/bar') }
    it { is_expected.to match('baz/foo/bar') }
    it { is_expected.to_not match('foo') }
    it { is_expected.to be_inclusive }
  end

  # If the pattern does not contain a slash '/', Git treats it as a shell glob
  # pattern and checks for a match against the pathname relative to the location
  # of the .gitignore file (relative to the toplevel of the work tree if not
  # from a .gitignore file).
  describe 'handles basic globbing' do
    subject { PathSpec::GitIgnoreSpec.new '*.tmp' }
    it { is_expected.to match('foo.tmp') }
    it { is_expected.to match('foo/bar.tmp') }
    it { is_expected.to match('foo/bar.tmp/baz') }
    it { is_expected.to_not match('foo.rb') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles inner globs' do
    subject { PathSpec::GitIgnoreSpec.new 'foo-*-bar' }
    it { is_expected.to match('foo--bar') }
    it { is_expected.to match('foo-hello-bar') }
    it { is_expected.to match('a/foo-hello-bar') }
    it { is_expected.to match('foo-hello-bar/b') }
    it { is_expected.to match('a/foo-hello-bar/b') }
    it { is_expected.to_not match('foo.tmp') }
  end

  describe 'handles postfix globs' do
    subject { PathSpec::GitIgnoreSpec.new '~temp-*' }
    it { is_expected.to match('~temp-') }
    it { is_expected.to match('~temp-foo') }
    it { is_expected.to match('foo/~temp-bar') }
    it { is_expected.to match('foo/~temp-bar/baz') }
    it { is_expected.to_not match('~temp') }
  end

  describe 'handles multiple globs' do
    subject { PathSpec::GitIgnoreSpec.new '*.middle.*' }
    it { is_expected.to match('hello.middle.rb') }
    it { is_expected.to_not match('foo.rb') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles dir globs' do
    subject { PathSpec::GitIgnoreSpec.new 'dir/*' }
    it { is_expected.to match('dir/foo') }
    it { is_expected.to_not match('foo/') }
    it { is_expected.to be_inclusive }
  end

  # Otherwise, Git treats the pattern as a shell glob suitable for consumption
  # by fnmatch(3) with the FNM_PATHNAME flag: wildcards in the pattern will not
  # match a / in the pathname. For example, "Documentation/*.html" matches
  # "Documentation/git.html" but not "Documentation/ppc/ppc.html" or
  # "tools/perf/Documentation/perf.html".
  describe 'handles dir globs' do
    subject { PathSpec::GitIgnoreSpec.new 'dir/*' }
    it { is_expected.to match('dir/foo') }
    it { is_expected.to_not match('foo/') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles globs inside of dirs' do
    subject { PathSpec::GitIgnoreSpec.new 'Documentation/*.html' }
    it { is_expected.to match('Documentation/git.html') }
    it { is_expected.to_not match('Documentation/ppc/ppc.html') }
    it { is_expected.to_not match('tools/perf/Documentation/perf.html') } # TODO: Or is it? Git 2 weirdness?
    it { is_expected.to be_inclusive }
  end

  describe 'handles wildcards' do
    subject { PathSpec::GitIgnoreSpec.new 'jokeris????' }
    it { is_expected.to match('jokeriswild') }
    it { is_expected.to_not match('jokerisfat') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles brackets' do
    subject { PathSpec::GitIgnoreSpec.new '*[eu][xl]*' }
    it { is_expected.to match('youknowregex') }
    it { is_expected.to match('youknowregularexpressions') }
    it { is_expected.to_not match('youknownothing') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles unmatched brackets' do
    subject { PathSpec::GitIgnoreSpec.new '*[*[*' }
    it { is_expected.to match('bracket[oh[wow') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles brackets with carats' do
    subject { PathSpec::GitIgnoreSpec.new '*[^]' }
    it { is_expected.to match('myfavorite^') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles brackets for brackets' do
    subject { PathSpec::GitIgnoreSpec.new '*[]]' }
    it { is_expected.to match('yodawg[]]') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles brackets with escaped characters' do
    # subject { GitIgnoreSpec.new 'back[\\]slash' }
    # it { is_expected.to match('back\\slash') }
    # it { is_expected.to_not match('back\\\\slash') }
    # it { is_expected.to be_inclusive }
  end

  describe 'handles negated brackets' do
    subject { PathSpec::GitIgnoreSpec.new 'ab[!cd]ef' }
    it { is_expected.to_not match('abcef') }
    it { is_expected.to match('abzef') }
    it { is_expected.to be_inclusive }
  end

  # A leading slash matches the beginning of the pathname. For example, "/*.c"
  # matches "cat-file.c" but not "mozilla-sha1/sha1.c".
  describe 'handles leading / as relative to base directory' do
    subject { PathSpec::GitIgnoreSpec.new '/*.c' }
    it { is_expected.to match('cat-file.c') }
    it { is_expected.to_not match('mozilla-sha1/sha1.c') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles simple single paths' do
    subject { PathSpec::GitIgnoreSpec.new 'spam' }
    it { is_expected.to match('spam') }
    it { is_expected.to match('spam/') }
    it { is_expected.to match('foo/spam') }
    it { is_expected.to match('spam/foo') }
    it { is_expected.to match('foo/spam/bar') }
    it { is_expected.to_not match('foo') }
  end

  # Two consecutive asterisks ("**") in patterns matched against full pathname
  # may have special meaning:

  # A leading "**" followed by a slash means match in all directories. For
  # example, "**/foo" matches file or directory "foo" anywhere, the same as
  # pattern "foo". "**/foo/bar" matches file or directory "bar" anywhere that is
  # directly under directory "foo".
  describe 'handles prefixed ** as searching any location' do
    subject { PathSpec::GitIgnoreSpec.new '**/foo' }
    it { is_expected.to match('foo') }
    it { is_expected.to match('bar/foo') }
    it { is_expected.to match('baz/bar/foo') }
    it { is_expected.to_not match('baz/bar/foo.rb') }
    it { is_expected.to be_inclusive }
  end

  describe 'handles prefixed ** with a directory as searching a file under a directory in any location' do
    subject { PathSpec::GitIgnoreSpec.new '**/foo/bar' }
    it { is_expected.to_not match('foo') }
    it { is_expected.to match('foo/bar') }
    it { is_expected.to match('baz/foo/bar') }
    it { is_expected.to match('baz/foo/bar/sub') }
    it { is_expected.to_not match('baz/foo/bar.rb') }
    it { is_expected.to_not match('baz/bananafoo/bar') }
    it { is_expected.to be_inclusive }
  end

  # A trailing "/**" matches everything inside. For example, "abc/**" matches
  # all files inside directory "abc", relative to the location of the .gitignore
  # file, with infinite depth.
  describe 'handles leading /** as all files inside a directory' do
    subject { PathSpec::GitIgnoreSpec.new 'abc/**' }
    it { is_expected.to match('abc/') }
    it { is_expected.to match('abc/def') }
    it { is_expected.to_not match('123/abc/def') }
    it { is_expected.to_not match('123/456/abc/') }
    it { is_expected.to be_inclusive }
  end

  # A slash followed by two consecutive asterisks then a slash matches zero or
  # more directories. For example, "a/**/b" matches "a/b", "a/x/b", "a/x/y/b"
  # and so on.
  describe 'handles /** in the middle of a path' do
    subject { PathSpec::GitIgnoreSpec.new 'a/**/b' }
    it { is_expected.to match('a/b') }
    it { is_expected.to match('a/x/b') }
    it { is_expected.to match('a/x/y/b') }
    it { is_expected.to_not match('123/a/b') }
    it { is_expected.to_not match('123/a/x/b') }
    it { is_expected.to be_inclusive }
  end

  describe 'matches all paths when given **' do
    subject { PathSpec::GitIgnoreSpec.new '**' }

    it { is_expected.to match('a/b') }
    it { is_expected.to match('a/x/b') }
    it { is_expected.to match('a/x/y/b') }
    it { is_expected.to match('123/a/b') }
    it { is_expected.to match('123/a/x/b') }
  end

  # Other consecutive asterisks are considered invalid.
  describe 'considers other consecutive asterisks invalid' do
    subject { PathSpec::GitIgnoreSpec.new 'a/***/b' }
    it { is_expected.to_not match('a/b') }
    it { is_expected.to_not match('a/x/b') }
    it { is_expected.to_not match('a/x/y/b') }
    it { is_expected.to_not match('123/a/b') }
    it { is_expected.to_not match('123/a/x/b') }
    it { is_expected.to_not be_inclusive }
  end

  describe 'does not match single absolute paths' do
    subject { PathSpec::GitIgnoreSpec.new '/' }
    it { is_expected.to_not match('foo.tmp') }
    it { is_expected.to_not match(' ') }
    it { is_expected.to_not match('a/b') }
  end

  describe 'nested paths are relative to the file' do
    subject { PathSpec::GitIgnoreSpec.new 'foo/spam' }
    it { is_expected.to match('foo/spam') }
    it { is_expected.to match('foo/spam/bar') }
    it { is_expected.to_not match('bar/foo/spam') }
  end
end
