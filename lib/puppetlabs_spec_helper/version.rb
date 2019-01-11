module PuppetlabsSpecHelper
  VERSION = '2.13.0'.freeze

  # compat for pre-1.2.0 users; deprecated
  module Version
    STRING = PuppetlabsSpecHelper::VERSION
  end
end
