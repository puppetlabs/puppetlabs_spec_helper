# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/container'
require 'hocon/config_error'

#
# Implemented by a merge stack (ConfigDelayedMerge, ConfigDelayedMergeObject)
# that replaces itself during substitution resolution in order to implement
# "look backwards only" semantics.
#
module Hocon::Impl::ReplaceableMergeStack
  include Hocon::Impl::Container

  #
  # Make a replacement for this object skipping the given number of elements
  # which are lower in merge priority.
  #
  def make_replacement(context, skipping)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `ReplaceableMergeStack` must implement `make_replacement` (#{self.class})"
  end
end
