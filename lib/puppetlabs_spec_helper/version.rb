module PuppetlabsSpecHelper
  VERSION = "2.6.1"

  # compat for pre-1.2.0 users; deprecated
  module Version
    STRING = PuppetlabsSpecHelper::VERSION
  end
end
