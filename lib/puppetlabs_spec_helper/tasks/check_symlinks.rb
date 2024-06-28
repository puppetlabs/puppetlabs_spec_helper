# frozen_string_literal: true

require 'pathspec'

module PuppetlabsSpecHelper
  module Tasks
    # Helpers for validating symlinks.
    class CheckSymlinks
      DEFAULT_IGNORED = [
        '/.git/',
        '/.bundle/',
        '/vendor/',
      ].freeze

      IGNORE_LIST_FILES = [
        '.pdkignore',
        '.gitignore',
      ].freeze

      def check(dir = Dir.pwd)
        dir = Pathname.new(dir) unless dir.is_a?(Pathname)
        results = []

        dir.each_child(true) do |child|
          next if ignored?(child.to_s)

          if child.symlink?
            results << child
          elsif child.directory? && child.basename.to_s !~ /^(\.git|\.?bundle)$/
            results.concat(check(child))
          end
        end

        results
      end

      def ignored?(path)
        path = "#{path}/" if File.directory?(path)

        !ignore_pathspec.match_paths([path], Dir.pwd).empty?
      end

      def ignore_pathspec
        @ignore_pathspec ||= PathSpec.new(DEFAULT_IGNORED).tap do |pathspec|
          IGNORE_LIST_FILES.each do |f|
            next unless File.file?(f) && File.readable?(f)

            File.open(f, 'r') { |fd| pathspec.add(fd) }
          end
        end
      end
    end
  end
end
