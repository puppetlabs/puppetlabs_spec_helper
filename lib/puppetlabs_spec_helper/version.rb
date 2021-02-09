# frozen_string_literal: true

module PuppetlabsSpecHelper
  VERSION = '2.16.0'

  # compat for pre-1.2.0 users; deprecated
  module Version
    STRING = PuppetlabsSpecHelper::VERSION
  end
end
