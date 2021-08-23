# frozen_string_literal: true

module PuppetlabsSpecHelper
  VERSION = '4.0.1'

  # compat for pre-1.2.0 users; deprecated
  module Version
    STRING = PuppetlabsSpecHelper::VERSION
  end
end
