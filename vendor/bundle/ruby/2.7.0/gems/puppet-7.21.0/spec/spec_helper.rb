# NOTE: a lot of the stuff in this file is duplicated in the "puppet_spec_helper" in the project
#  puppetlabs_spec_helper.  We should probably eat our own dog food and get rid of most of this from here,
#  and have the puppet core itself use puppetlabs_spec_helper

dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(dir, 'lib')

# Don't want puppet getting the command line arguments for rake
ARGV.clear

begin
  require 'rubygems'
rescue LoadError
end

require 'puppet'

# Stub out gettext's `_` and `n_()` methods, which attempt to load translations.
# Several of our mocks (mostly around file system interaction) are broken by
# FastGettext's implementation of these methods.
require 'puppet/gettext/stubs'

require 'rspec'
require 'rspec/its'

# So everyone else doesn't have to include this base constant.
module PuppetSpec
  FIXTURE_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "fixtures") unless defined?(FIXTURE_DIR)
end

require 'pathname'
require 'tmpdir'
require 'fileutils'

require 'puppet_spec/verbose'
require 'puppet_spec/files'
require 'puppet_spec/settings'
require 'puppet_spec/fixtures'
require 'puppet_spec/matchers'
require 'puppet_spec/unindent'
require 'puppet/test/test_helper'

Pathname.glob("#{dir}/shared_contexts/*.rb") do |file|
  require file.relative_path_from(Pathname.new(dir))
end

Pathname.glob("#{dir}/shared_behaviours/**/*.rb") do |behaviour|
  require behaviour.relative_path_from(Pathname.new(dir))
end

Pathname.glob("#{dir}/shared_examples/**/*.rb") do |behaviour|
  require behaviour.relative_path_from(Pathname.new(dir))
end

require 'webmock/rspec'
require 'vcr'
VCR.configure do |vcr|
  vcr.cassette_library_dir = File.expand_path('vcr/cassettes', PuppetSpec::FIXTURE_DIR)
  vcr.hook_into :webmock
  vcr.configure_rspec_metadata!
  # Uncomment next line to debug vcr
  # vcr.debug_logger = $stderr
end

# Disable VCR by default
VCR.turn_off!

RSpec.configure do |config|
  include PuppetSpec::Fixtures

  exclude_filters = {}
  exclude_filters[:benchmark] = true unless ENV['BENCHMARK']
  config.filter_run_excluding exclude_filters

  config.filter_run_when_matching :focus

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  tmpdir = Puppet::FileSystem.expand_path(Dir.mktmpdir("rspecrun"))
  oldtmpdir = Puppet::FileSystem.expand_path(Dir.tmpdir())
  ENV['TMPDIR'] = tmpdir

  Puppet::Test::TestHelper.initialize

  config.before :all do
    Puppet::Test::TestHelper.before_all_tests()
    if ENV['PROFILE'] == 'all'
      require 'ruby-prof'
      RubyProf.start
    end
  end

  config.after :all do
    if ENV['PROFILE'] == 'all'
      require 'ruby-prof'
      result = RubyProf.stop
      printer = RubyProf::CallTreePrinter.new(result)
      open(File.join(ENV['PROFILEOUT'],"callgrind.all.#{Time.now.to_i}.trace"), "w") do |f|
        printer.print(f)
      end
    end

    Puppet::Test::TestHelper.after_all_tests()
  end

  config.before :each do |test|
    # Disabling garbage collection inside each test, and only running it at
    # the end of each block, gives us an ~ 15 percent speedup, and more on
    # some platforms *cough* windows *cough* that are a little slower.
    GC.disable

    # TODO: in a more sane world, we'd move this logging redirection into our TestHelper class.
    #  Without doing so, external projects will all have to roll their own solution for
    #  redirecting logging, and for validating expected log messages.  However, because the
    #  current implementation of this involves creating an instance variable "@logs" on
    #  EVERY SINGLE TEST CLASS, and because there are over 1300 tests that are written to expect
    #  this instance variable to be available--we can't easily solve this problem right now.
    #
    # redirecting logging away from console, because otherwise the test output will be
    #  obscured by all of the log output
    @logs = []
    Puppet::Util::Log.close_all
    if ENV["PUPPET_TEST_LOG_LEVEL"]
      Puppet::Util::Log.level = ENV["PUPPET_TEST_LOG_LEVEL"].intern
    end
    if ENV["PUPPET_TEST_LOG"]
      Puppet::Util::Log.newdestination(ENV["PUPPET_TEST_LOG"])
      m = test.metadata
      Puppet.notice("*** BEGIN TEST #{m[:file_path]}:#{m[:line_number]}")
    end
    Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(@logs))

    @log_level = Puppet::Util::Log.level

    base = PuppetSpec::Files.tmpdir('tmp_settings')
    Puppet[:vardir] = File.join(base, 'var')
    Puppet[:publicdir] = File.join(base, 'public')
    Puppet[:confdir] = File.join(base, 'etc')
    Puppet[:codedir] = File.join(base, 'code')
    Puppet[:logdir] = "$vardir/log"
    Puppet[:rundir] = "$vardir/run"
    Puppet[:hiera_config] = File.join(base, 'hiera')

    FileUtils.mkdir_p Puppet[:statedir]
    FileUtils.mkdir_p Puppet[:publicdir]

    Puppet::Test::TestHelper.before_each_test()
  end

  # Facter 2 uses two versions of the GCE API, so match using regex
  PUPPET_FACTER_2_GCE_URL = %r{^http://metadata/computeMetadata/v1(beta1)?}.freeze
  PUPPET_FACTER_3_GCE_URL = "http://metadata.google.internal/computeMetadata/v1/?recursive=true&alt=json".freeze

  # Facter azure metadata endpoint
  PUPPET_FACTER_AZ_URL = "http://169.254.169.254/metadata/instance?api-version=2020-09-01"

  # Facter EC2 endpoint
  PUPPET_FACTER_EC2_METADATA = 'http://169.254.169.254/latest/meta-data/'
  PUPPET_FACTER_EC2_USERDATA = 'http://169.254.169.254/latest/user-data/'

  config.around :each do |example|
    # Ignore requests from Facter to external services
    stub_request(:get, PUPPET_FACTER_2_GCE_URL)
    stub_request(:get, PUPPET_FACTER_3_GCE_URL)
    stub_request(:get, PUPPET_FACTER_AZ_URL)
    stub_request(:get, PUPPET_FACTER_EC2_METADATA)
    stub_request(:get, PUPPET_FACTER_EC2_USERDATA)

    # Enable VCR if the example is tagged with `:vcr` metadata.
    if example.metadata[:vcr]
      VCR.turn_on!
      begin
        example.run
      ensure
        VCR.turn_off!
      end
    else
      example.run
    end
  end

  config.after :each do
    Puppet::Test::TestHelper.after_each_test()

    # TODO: would like to move this into puppetlabs_spec_helper, but there are namespace issues at the moment.
    allow(Dir).to receive(:entries).and_call_original
    PuppetSpec::Files.cleanup

    # TODO: this should be abstracted in the future--see comments above the '@logs' block in the
    #  "before" code above.
    #
    # clean up after the logging changes that we made before each test.
    @logs.clear
    Puppet::Util::Log.close_all
    Puppet::Util::Log.level = @log_level

    # This will perform a GC between tests, but only if actually required.  We
    # experimented with forcing a GC run, and that was less efficient than
    # just letting it run all the time.
    GC.enable
  end

  config.after :suite do
    # Log the spec order to a file, but only if the LOG_SPEC_ORDER environment variable is
    #  set.  This should be enabled on Jenkins runs, as it can be used with Nick L.'s bisect
    #  script to help identify and debug order-dependent spec failures.
    if ENV['LOG_SPEC_ORDER']
      File.open("./spec_order.txt", "w") do |logfile|
        config.instance_variable_get(:@files_to_run).each { |f| logfile.puts f }
      end
    end

    # return to original tmpdir
    ENV['TMPDIR'] = oldtmpdir
    FileUtils.rm_rf(tmpdir)
  end

  if ENV['PROFILE']
    require 'ruby-prof'

    def profile
      result = RubyProf.profile { yield }
      name = RSpec.current_example.metadata[:full_description].downcase.gsub(/[^a-z0-9_-]/, "-").gsub(/-+/, "-")
      printer = RubyProf::CallTreePrinter.new(result)
      open(File.join(ENV['PROFILEOUT'],"callgrind.#{name}.#{Time.now.to_i}.trace"), "w") do |f|
        printer.print(f)
      end
    end

    config.around(:each) do |example|
      if ENV['PROFILE'] == 'each' or (example.metadata[:profile] and ENV['PROFILE'])
        profile { example.run }
      else
        example.run
      end
    end
  end
end
