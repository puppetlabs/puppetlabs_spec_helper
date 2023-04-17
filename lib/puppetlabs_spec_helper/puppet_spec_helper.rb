# frozen_string_literal: true

require 'puppetlabs_spec_helper/puppetlabs_spec_helper'

# Don't want puppet getting the command line arguments for rake or autotest
ARGV.clear

require 'puppet'
require 'rspec/expectations'

# Detect whether the module is overriding the choice of mocking framework
# @mock_framework is used since more than seven years, and we need to avoid
# `mock_framework`'s autoloading to distinguish between the default, and
# the module's choice.
# See also below in RSpec.configure
if RSpec.configuration.instance_variable_get(:@mock_framework).nil?
  # This is needed because we're using mocha with rspec instead of Test::Unit or MiniTest
  ENV['MOCHA_OPTIONS'] = 'skip_integration'

  # Current versions of RSpec already load this for us, but who knows what's used out there?
  require 'mocha/api'
end

require 'pathname'
require 'tmpdir'

require 'puppetlabs_spec_helper/puppetlabs_spec/files'

######################################################################################
#                                     WARNING                                        #
######################################################################################
#
# You should probably be frightened by this file.  :)
#
# The goal of this file is to try to maximize spec-testing compatibility between
# multiple versions of various external projects (which depend on puppet core) and
# multiple versions of puppet core itself.  This is accomplished via a series
# of hacks and magical incantations that I am not particularly proud of.  However,
# after discussion it was decided that the goal of achieving compatibility was
# a very worthy one, and that isolating the hacks to one place in a non-production
# project was as good a solution as we could hope for.
#
# You may want to hold your nose before you proceed. :)
#

# Here we attempt to load the new TestHelper API, and print a warning if we are falling back
# to compatibility mode for older versions of puppet.
begin
  require 'puppet/test/test_helper'
rescue LoadError
  # Continue gracefully
end

# And here is where we do the main rspec configuration / setup.
RSpec.configure do |config|
  # Detect whether the module is overriding the choice of mocking framework
  # @mock_framework is used since more than seven years, and we need to avoid
  # `mock_framework`'s autoloading to distinguish between the default, and
  # the module's choice.
  config.mock_with :rspec if config.instance_variable_get(:@mock_framework).nil?

  # Here we do some general setup that is relevant to all initialization modes, regardless
  # of the availability of the TestHelper API.

  config.before :each do
    # Here we redirect logging away from console, because otherwise the test output will be
    #  obscured by all of the log output.
    #
    # TODO: in a more sane world, we'd move this logging redirection into our TestHelper
    #  class, so that it was not coupled with a specific testing framework (rspec in this
    #  case).  Further, it would be nicer and more portable to encapsulate the log messages
    #  into an object somewhere, rather than slapping them on an instance variable of the
    #  actual test class--which is what we are effectively doing here.
    #
    # However, because there are over 1300 tests that are written to expect
    #  this instance variable to be available--we can't easily solve this problem right now.
    @logs = []
    Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(@logs))

    @log_level = Puppet::Util::Log.level
  end

  config.after :each do
    # clean up after the logging changes that we made before each test.

    # TODO: this should be abstracted in the future--see comments above the '@logs' block in the
    #  "before" code above.
    @logs.clear
    Puppet::Util::Log.close_all
    Puppet::Util::Log.level = @log_level
  end
end
