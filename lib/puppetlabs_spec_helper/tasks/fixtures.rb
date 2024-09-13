# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'json'

module PuppetlabsSpecHelper
  module Tasks
    # Helpers for working with fixtures.
    module FixtureHelpers
      # This is a helper for the self-symlink entry of fixtures.yml
      def source_dir
        Dir.pwd
      end

      # @return [String] - the name of current module
      def module_name
        raise ArgumentError unless File.file?('metadata.json') && File.readable?('metadata.json')

        metadata = JSON.parse(File.read('metadata.json'))
        metadata_name = metadata.fetch('name', nil) || ''

        raise ArgumentError if metadata_name.empty?

        metadata_name.split('-').last
      rescue JSON::ParserError, ArgumentError
        File.basename(Dir.pwd).split('-').last
      end

      def module_version(path)
        metadata_path = File.join(path, 'metadata.json')
        raise ArgumentError unless File.file?(metadata_path) && File.readable?(metadata_path)

        metadata = JSON.parse(File.read(metadata_path))
        metadata.fetch('version', nil) || '0.0.1'
      rescue JSON::ParserError, ArgumentError
        logger.warn "Failed to find module version at path #{path}"
        '0.0.1'
      end

      # @return [Hash] - returns a hash of all the fixture repositories
      # @example
      # {"puppetlabs-stdlib"=>{"target"=>"https://gitlab.com/puppetlabs/puppet-stdlib.git",
      # "ref"=>nil, "branch"=>"main", "scm"=>nil,
      # }}
      def repositories
        @repositories ||= fixtures('repositories') || {}
      end

      # @return [Hash] - returns a hash of all the fixture forge modules
      # @example
      # {"puppetlabs-stdlib"=>{"target"=>"spec/fixtures/modules/stdlib",
      # "ref"=>nil, "branch"=>nil, "scm"=>nil,
      # "flags"=>"--module_repository=https://myforge.example.com/", "subdir"=>nil}}
      def forge_modules
        @forge_modules ||= fixtures('forge_modules') || {}
      end

      # @return [Hash] - a hash of symlinks specified in the fixtures file
      def symlinks
        @symlinks ||= fixtures('symlinks') || {}
      end

      # @return [Hash] - returns a hash with the module name and the source directory
      def auto_symlink
        { module_name => "\#{source_dir}" }
      end

      # @return [Boolean] - true if the os is a windows system
      def windows?
        !!File::ALT_SEPARATOR
      end

      def fixtures(category)
        fixtures_yaml = if ENV['FIXTURES_YML']
                          ENV['FIXTURES_YML']
                        elsif File.exist?('.fixtures.yml')
                          '.fixtures.yml'
                        elsif File.exist?('.fixtures.yaml')
                          '.fixtures.yaml'
                        else
                          false
                        end

        begin
          fixtures = if fixtures_yaml
                       YAML.load_file(fixtures_yaml) || { 'fixtures' => {} }
                     else
                       { 'fixtures' => {} }
                     end
        rescue Errno::ENOENT
          raise("Fixtures file not found: '#{fixtures_yaml}'")
        rescue Psych::SyntaxError => e
          raise("Found malformed YAML in '#{fixtures_yaml}' on line #{e.line} column #{e.column}: #{e.problem}")
        end

        unless fixtures.include?('fixtures')
          # File is non-empty, but does not specify fixtures
          raise("No 'fixtures' entries found in '#{fixtures_yaml}'; required")
        end

        fixture_defaults = if fixtures.include? 'defaults'
                             fixtures['defaults']
                           else
                             {}
                           end

        fixtures = fixtures['fixtures']
        fixtures['symlinks'] = (fixtures['symlinks'].nil? || fixtures['symlinks'].empty?) ? auto_symlink : auto_symlink.merge!(fixtures['symlinks'])

        result = {}
        if fixtures.include?(category) && !fixtures[category].nil?
          defaults = { 'target' => 'spec/fixtures/modules' }

          # load defaults from the `.fixtures.yml` `defaults` section
          # for the requested category and merge them into my defaults
          defaults = defaults.merge(fixture_defaults[category]) if fixture_defaults.include? category

          fixtures[category].each do |fixture, opts|
            # convert a simple string fixture to a hash, by
            # using the string fixture as the `repo` option of the hash.
            opts = { 'repo' => opts } if opts.instance_of?(String)
            # there should be a warning or something if it's not a hash...
            next unless opts.instance_of?(Hash)

            # merge our options into the defaults to get the
            # final option list
            opts = defaults.merge(opts)

            next unless include_repo?(opts['puppet_version'])

            real_target = eval("\"#{opts['target']}\"", binding, __FILE__, __LINE__) # evaluating target reference in this context (see auto_symlink)
            real_source = eval("\"#{opts['repo']}\"", binding, __FILE__, __LINE__) # evaluating repo reference in this context (see auto_symlink)

            result[real_source] = validate_fixture_hash!(
              'target' => File.join(real_target, fixture),
              'ref' => opts['ref'] || opts['tag'],
              'branch' => opts['branch'],
              'scm' => opts['scm'],
              'flags' => opts['flags'],
              'subdir' => opts['subdir'],
            )
          end
        end
        result
      end

      def validate_fixture_hash!(hash)
        # Can only validate git based scm
        return hash unless hash['scm'] == 'git'

        # Forward slashes in the ref aren't allowed. And is probably a branch name.
        raise ArgumentError, "The ref for #{hash['target']} is invalid (Contains a forward slash). If this is a branch name, please use the 'branch' setting instead." if hash['ref']&.include?('/')

        hash
      end

      def include_repo?(version_range)
        if version_range && defined?(SemanticPuppet)
          puppet_spec = Gem::Specification.find_by_name('puppet')
          puppet_version = SemanticPuppet::Version.parse(puppet_spec.version.to_s)

          constraint = SemanticPuppet::VersionRange.parse(version_range)
          constraint.include?(puppet_version)
        else
          true
        end
      end

      def clone_repo(scm, remote, target, _subdir = nil, ref = nil, branch = nil, flags = nil)
        args = []
        case scm
        when 'hg'
          args.push('clone')
          args.push('-b', branch) if branch
          args.push(flags) if flags
          args.push(remote, target)
        when 'git'
          args.push('clone')
          args.push('--depth 1') unless ref
          args.push('-b', branch) if branch
          args.push(flags) if flags
          args.push(remote, target)
        else
          raise "Unfortunately #{scm} is not supported yet"
        end
        result = system("#{scm} #{args.flatten.join ' '}")
        raise "Failed to clone #{scm} repository #{remote} into #{target}" unless File.exist?(target)

        result
      end

      def update_repo(scm, target)
        args = case scm
               when 'hg'
                 ['pull']
               when 'git'
                 ['fetch'].tap do |git_args|
                   git_args << '--unshallow' if shallow_git_repo?
                 end
               else
                 raise "Unfortunately #{scm} is not supported yet"
               end
        system("#{scm} #{args.flatten.join(' ')}", chdir: target)
      end

      def shallow_git_repo?
        File.file?(File.join('.git', 'shallow'))
      end

      def revision(scm, target, ref)
        args = []
        case scm
        when 'hg'
          args.push('update', '--clean', '-r', ref)
        when 'git'
          args.push('reset', '--hard', ref)
        else
          raise "Unfortunately #{scm} is not supported yet"
        end
        result = system("#{scm} #{args.flatten.join ' '}", chdir: target)
        raise "Invalid ref #{ref} for #{target}" unless result
      end

      def valid_repo?(scm, target, remote)
        return false unless File.directory?(target)
        return true if scm == 'hg'

        return true if git_remote_url(target) == remote

        warn "Git remote for #{target} has changed, recloning repository"
        FileUtils.rm_rf(target)
        false
      end

      def git_remote_url(target)
        output, status = Open3.capture2e('git', '--git-dir', File.join(target, '.git'), 'ls-remote', '--get-url', 'origin')
        status.success? ? output.strip : nil
      end

      def remove_subdirectory(target, subdir)
        return if subdir.nil?

        Dir.mktmpdir do |tmpdir|
          FileUtils.mv(Dir.glob("#{target}/#{subdir}/{.[^.]*,*}"), tmpdir)
          FileUtils.rm_rf("#{target}/#{subdir}")
          FileUtils.mv(Dir.glob("#{tmpdir}/{.[^.]*,*}"), target.to_s)
        end
      end

      # creates a logger so we can log events with certain levels
      def logger
        unless @logger
          require 'logger'
          level = if ENV['ENABLE_LOGGER']
                    Logger::DEBUG
                  else
                    Logger::INFO
                  end
          @logger = Logger.new($stderr)
          @logger.level = level
        end
        @logger
      end

      def module_working_directory
        # The problem with the relative path is that PMT doesn't expand the path properly and so passing in a relative path here
        # becomes something like C:\somewhere\backslashes/spec/fixtures/work-dir on Windows, and then PMT barfs itself.
        # This has been reported as https://tickets.puppetlabs.com/browse/PUP-4884
        File.expand_path(ENV['MODULE_WORKING_DIR'] || 'spec/fixtures/work-dir')
      end

      # returns the current thread count that is currently active
      # a status of false or nil means the thread completed
      # so when anything else we count that as a active thread
      # @return [Integer] - current thread count
      def current_thread_count(items)
        active_threads = items.select do |_item, opts|
          if opts[:thread]
            opts[:thread].status
          else
            false
          end
        end
        logger.debug "Current thread count #{active_threads.count}"
        active_threads.count
      end

      # @summary Set a limit on the amount threads used, defaults to 10
      #   MAX_FIXTURE_THREAD_COUNT can be used to set this limit
      # @return [Integer] - returns the max_thread_count
      def max_thread_limit
        @max_thread_limit ||= (ENV['MAX_FIXTURE_THREAD_COUNT'] || 10).to_i
      end

      # @param items [Hash] - a hash of either repositories or forge modules
      # @param [Block] - the method you wish to use to download the item
      def download_items(items)
        items.each do |remote, opts|
          # get the current active threads that are alive
          count = current_thread_count(items)
          if count < max_thread_limit
            logger.debug "New Thread started for #{remote}"
            # start up a new thread and store it in the opts hash
            opts[:thread] = Thread.new do
              yield(remote, opts)
            end
          else
            # the last thread started should be the longest wait
            # Rubocop seems to push towards using select here.. however the implementation today relies on the result being
            # an array. Select returns a hash which makes it unsuitable so we need to use find_all.last.
            item, item_opts = items.find_all { |_i, o| o.key?(:thread) }.last # rubocop:disable Performance/Detect
            logger.debug "Waiting on #{item}"
            item_opts[:thread].join # wait for the thread to finish
            # now that we waited lets try again
            redo
          end
        end
        # wait for all the threads to finish
        items.each_value { |opts| opts[:thread].join }
      end

      # @param target [String] - the target directory
      # @param link [String] - the name of the link you wish to create
      # works on windows and linux
      def setup_symlink(target, link)
        link = link['target']
        return if File.symlink?(link)

        logger.info("Creating symlink from #{link} to #{target}")
        if windows?
          target = File.join(File.dirname(link), target) unless Pathname.new(target).absolute?
          if Dir.respond_to?(:create_junction)
            Dir.create_junction(link, target)
          else
            system("call mklink /J \"#{link.tr('/', '\\')}\" \"#{target.tr('/', '\\')}\"")
          end
        else
          FileUtils.ln_sf(target, link)
        end
      end

      # @return [Boolean] - returns true if the module was downloaded successfully, false otherwise
      # @param [String] - the remote url or namespace/name of the module to download
      # @param [Hash] - list of options such as version, branch, ref
      def download_repository(remote, opts)
        scm = 'git'
        target = opts['target']
        subdir = opts['subdir']
        ref = opts['ref']
        scm = opts['scm'] if opts['scm']
        branch = opts['branch'] if opts['branch']
        flags = opts['flags']
        if valid_repo?(scm, target, remote)
          update_repo(scm, target)
        else
          clone_repo(scm, remote, target, subdir, ref, branch, flags)
        end
        revision(scm, target, ref) if ref
        remove_subdirectory(target, subdir) if subdir
      end

      # @return [String] - the spec/fixtures/modules directory in the module root folder
      def module_target_dir
        @module_target_dir ||= File.expand_path('spec/fixtures/modules')
      end

      # @return [Boolean] - returns true if the module was downloaded successfully, false otherwise
      # @param [String] - the remote url or namespace/name of the module to download
      # @param [Hash] - list of options such as version
      def download_module(remote, opts)
        ref = ''
        flags = ''
        if opts.instance_of?(String)
          target = opts
        elsif opts.instance_of?(Hash)
          target = opts['target']
          ref = " --version #{opts['ref']}" unless opts['ref'].nil?
          flags = " #{opts['flags']}" if opts['flags']
        end

        forge_token = ENV.fetch('FORGE_API_KEY', nil)
        flags += " --forge_authorization \"Bearer #{forge_token}\"" if forge_token

        return false if File.directory?(target) && (ref.empty? || opts['ref'] == module_version(target))

        # The PMT cannot handle multi threaded runs due to cache directory collisons
        # so we randomize the directory instead.
        # Does working_dir even need to be passed?
        Dir.mktmpdir do |working_dir|
          command = "puppet module install#{ref}#{flags} --ignore-dependencies " \
                    '--force ' \
                    "--module_working_dir \"#{working_dir}\" " \
                    "--target-dir \"#{module_target_dir}\" \"#{remote}\""

          raise "Failed to install module #{remote} to #{module_target_dir}" unless system(command)
        end
        $CHILD_STATUS.success?
      end
    end
  end
end

include PuppetlabsSpecHelper::Tasks::FixtureHelpers # DSL include

desc 'Create the fixtures directory'
task :spec_prep do
  # Ruby only sets File::ALT_SEPARATOR on Windows and Rubys standard library
  # uses this to check for Windows
  if windows?
    begin
      require 'win32/dir'
    rescue LoadError
      warn 'win32-dir gem not installed, falling back to executing mklink directly'
    end
  end

  # git has a race condition creating that directory, that would lead to aborted clone operations
  FileUtils.mkdir_p('spec/fixtures/modules')

  symlinks.each { |target, link| setup_symlink(target, link) }

  download_items(repositories) { |remote, opts| download_repository(remote, opts) }

  download_items(forge_modules) { |remote, opts| download_module(remote, opts) }

  FileUtils.mkdir_p('spec/fixtures/manifests')
  FileUtils.touch('spec/fixtures/manifests/site.pp')
end

desc 'Clean up the fixtures directory'
task :spec_clean do
  repositories.each_value do |opts|
    target = opts['target']
    FileUtils.rm_rf(target)
  end

  forge_modules.each_value do |opts|
    target = opts['target']
    FileUtils.rm_rf(target)
  end

  FileUtils.rm_rf(module_working_directory)

  Rake::Task[:spec_clean_symlinks].invoke

  FileUtils.rm_f('spec/fixtures/manifests/site.pp') if File.empty?('spec/fixtures/manifests/site.pp')
end

desc 'Clean up any fixture symlinks'
task :spec_clean_symlinks do
  fixtures('symlinks').each_value do |opts|
    target = opts['target']
    FileUtils.rm_f(target)
  end
end
