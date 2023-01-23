require "puppet-syntax/version"
require "puppet-syntax/manifests"
require "puppet-syntax/templates"
require "puppet-syntax/hiera"
require "puppet/version"

module PuppetSyntax
  @exclude_paths = []
  @hieradata_paths = [
    "**/data/**/*.*{yaml,yml}",
    "hieradata/**/*.*{yaml,yml}",
    "hiera*.*{yaml,yml}"
  ]
  @manifests_paths = [
    '**/*.pp'
  ]
  @templates_paths = [
    '**/templates/**/*.erb',
    '**/templates/**/*.epp'
  ]
  @fail_on_deprecation_notices = true
  @check_hiera_keys = false

  class << self
    attr_accessor :exclude_paths,
                  :hieradata_paths,
                  :manifests_paths,
                  :templates_paths,
                  :fail_on_deprecation_notices,
                  :epp_only,
                  :check_hiera_keys
  end
end
