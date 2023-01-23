# encoding: utf-8

require 'hocon/impl'
require 'hocon/config_value'
require 'hocon/config_error'

# An AbstractConfigValue which contains other values. Java has no way to
# express "this has to be an AbstractConfigValue also" other than making
# AbstractConfigValue an interface which would be aggravating. But we can say
# we are a ConfigValue.
module Hocon::Impl::Container
  include Hocon::ConfigValue
  #
  # Replace a child of this value. CAUTION if replacement is null, delete the
  # child, which may also delete the parent, or make the parent into a
  # non-container.
  #
  def replace_child(child, replacement)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Container` must implement `replace_child` (#{self.class})"
  end

  #
  # Super-expensive full traversal to see if descendant is anywhere
  # underneath this container.
  #
  def has_descendant?(descendant)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Container` must implement `has_descendant?` (#{self.class})"
  end
end
