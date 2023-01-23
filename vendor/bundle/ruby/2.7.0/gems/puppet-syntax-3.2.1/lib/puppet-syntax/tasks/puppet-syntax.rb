require 'puppet-syntax'
require 'rake'
require 'rake/tasklib'

module PuppetSyntax
  class RakeTask < ::Rake::TaskLib
    def filelist(paths)
      excludes = PuppetSyntax.exclude_paths
      excludes.push('pkg/**/*')
      excludes.push('vendor/**/*')
      files = FileList[paths]
      files.reject! { |f| File.directory?(f) }
      files.exclude(*excludes)
    end

    def filelist_manifests
      filelist(PuppetSyntax.manifests_paths)
    end

    def filelist_templates
      filelist(PuppetSyntax.templates_paths)
    end

    def filelist_hiera_yaml
      filelist(PuppetSyntax.hieradata_paths)
    end

    def initialize(*args)
      desc 'Syntax check Puppet manifests and templates'
      task :syntax => [
        'syntax:manifests',
        'syntax:templates',
        'syntax:hiera',
      ]

      namespace :syntax do
        desc 'Syntax check Puppet manifests'
        task :manifests do |t|
          $stderr.puts "---> #{t.name}"

          c = PuppetSyntax::Manifests.new
          output, has_errors = c.check(filelist_manifests)
          $stdout.puts "#{output.join("\n")}\n" unless output.empty?
          exit 1 if has_errors || ( output.any? && PuppetSyntax.fail_on_deprecation_notices )
        end

        desc 'Syntax check Puppet templates'
        task :templates do |t|
          $stderr.puts "---> #{t.name}"

          c = PuppetSyntax::Templates.new
          result = c.check(filelist_templates)
          unless result[:warnings].empty?
            $stdout.puts "WARNINGS:"
            $stdout.puts result[:warnings].join("\n")
          end
          unless result[:errors].empty?
            $stderr.puts "ERRORS:"
            $stderr.puts result[:errors].join("\n")
            exit 1
          end
        end

        desc 'Syntax check Hiera config files'
        task :hiera => [
          'syntax:hiera:yaml',
        ]

        namespace :hiera do
          task :yaml do |t|
            $stderr.puts "---> #{t.name}"
            c = PuppetSyntax::Hiera.new
            errors = c.check(filelist_hiera_yaml)
            $stdout.puts "#{errors.join("\n")}\n" unless errors.empty?
            exit 1 unless errors.empty?
          end
        end
      end
    end
  end
end

PuppetSyntax::RakeTask.new
