# encoding: utf-8

require 'hocon/impl'
require 'hocon/config_error'


#
# Interface that tags a ConfigValue that is not mergeable until after
# substitutions are resolved. Basically these are special ConfigValue that
# never appear in a resolved tree, like {@link ConfigSubstitution} and
# {@link ConfigDelayedMerge}.
#
module Hocon::Impl::Unmergeable
  def unmerged_values
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Unmergeable` must implement `unmerged_values` (#{self.class})"
  end
end
