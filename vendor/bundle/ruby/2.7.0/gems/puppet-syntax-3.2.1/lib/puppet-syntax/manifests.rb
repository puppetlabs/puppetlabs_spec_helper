module PuppetSyntax
  class Manifests
    def check(filelist)
      raise "Expected an array of files" unless filelist.is_a?(Array)
      require 'puppet'
      require 'puppet/face'
      require 'puppet/test/test_helper'

      output = []

      Puppet::Test::TestHelper.initialize
      Puppet::Test::TestHelper.before_all_tests
      called_before_all_tests = true

      # Catch syntax warnings.
      Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(output))
      Puppet::Util::Log.level = :warning

      filelist.each do |puppet_file|
        Puppet::Test::TestHelper.before_each_test
        begin
          error = validate_manifest(puppet_file)
          if error.is_a?(Hash) # Puppet 6.5.0 onwards
            output << error.values.first unless error.empty?
          end
        rescue SystemExit
          # Disregard exit(1) from face.
          # This is how puppet < 6.5.0 `validate_manifest` worked.
        rescue => error
          output << error
        ensure
          Puppet::Test::TestHelper.after_each_test
        end
      end

      Puppet::Util::Log.close_all
      output.map! { |e| e.to_s }

      # Exported resources will raise warnings when outside a puppetmaster.
      output.reject! { |e|
        e =~ /^You cannot collect( exported resources)? without storeconfigs being set/
      }

      # tag and schedule parameters in class raise warnings notice in output that prevent from succeed
      output.reject! { |e|
        e =~ /^(tag|schedule) is a metaparam; this value will inherit to all contained resources in the /
      }

      deprecations = output.select { |e|
        e =~ /^Deprecation notice:|is deprecated/
      }

      # Errors exist if there is any output that isn't a deprecation notice.
      has_errors = (output != deprecations)

      return output, has_errors
    ensure
      Puppet::Test::TestHelper.after_all_tests if called_before_all_tests
    end

    private
    def validate_manifest(file)
      Puppet[:tasks] = true if Puppet::Util::Package.versioncmp(Puppet.version, '5.4.0') >= 0 and file.match(/.*plans\/.*\.pp$/)
      Puppet::Face[:parser, :current].validate(file)
    end
  end
end
