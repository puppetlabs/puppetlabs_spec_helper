module PuppetlabsSpecHelper
  VERSION = "2.0.3"

  # compat for pre-1.2.0 users; deprecated
  module Version
    STRING = PuppetlabsSpecHelper::VERSION
  end
end
