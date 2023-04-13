# frozen_string_literal: true

module PuppetlabsSpec
  # This module provides some helper methods to assist with fixtures. It's
  # methods are designed to help when you have a conforming fixture layout so we
  # get project consistency.
  module Fixtures
    # Returns the joined path of the global FIXTURE_DIR plus any path given to it
    def fixtures(*rest)
      File.join(PuppetlabsSpec::FIXTURE_DIR, *rest)
    end

    # Returns the path to your relative fixture dir. So if your spec test is
    # <project>/spec/unit/facter/foo_spec.rb then your relative dir will be
    # <project>/spec/fixture/unit/facter/foo
    def my_fixture_dir
      callers = caller
      while (line = callers.shift)
        next unless (found = line.match(%r{/spec/(.*)_spec\.rb:}))

        return fixtures(found[1])
      end
      raise "sorry, I couldn't work out your path from the caller stack!"
    end

    # Given a name, returns the full path of a file from your relative fixture
    # dir as returned by my_fixture_dir.
    def my_fixture(name)
      file = File.join(my_fixture_dir, name)
      raise "fixture '#{name}' for #{my_fixture_dir} is not readable" unless File.readable? file

      file
    end

    # Return the contents of the file using read when given a name. Uses
    # my_fixture to work out the relative path.
    def my_fixture_read(name)
      File.read(my_fixture(name))
    end

    # Provides a block mechanism for iterating across the files in your fixture
    # area.
    def my_fixtures(glob = '*', flags = 0, &block)
      files = Dir.glob(File.join(my_fixture_dir, glob), flags)
      raise "fixture '#{glob}' for #{my_fixture_dir} had no files!" if files.empty?

      block && files.each(&block)
      files
    end
  end
end
