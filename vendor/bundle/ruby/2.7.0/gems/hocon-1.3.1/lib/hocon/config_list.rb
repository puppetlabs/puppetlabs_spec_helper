# encoding: utf-8

require 'hocon'
require 'hocon/config_value'
require 'hocon/config_error'

#
# Subtype of {@link ConfigValue} representing a list value, as in JSON's
# {@code [1,2,3]} syntax.
#
# <p>
# {@code ConfigList} implements {@code java.util.List<ConfigValue>} so you can
# use it like a regular Java list. Or call {@link #unwrapped()} to unwrap the
# list elements into plain Java values.
#
# <p>
# Like all {@link ConfigValue} subtypes, {@code ConfigList} is immutable. This
# makes it threadsafe and you never have to create "defensive copies." The
# mutator methods from {@link java.util.List} all throw
# {@link java.lang.UnsupportedOperationException}.
#
# <p>
# The {@link ConfigValue#valueType} method on a list returns
# {@link ConfigValueType#LIST}.
#
# <p>
# <em>Do not implement {@code ConfigList}</em>; it should only be implemented
# by the config library. Arbitrary implementations will not work because the
# library internals assume a specific concrete implementation. Also, this
# interface is likely to grow new methods over time, so third-party
# implementations will break.
#
#
module Hocon::ConfigList
  include Hocon::ConfigValue

  #
  # Recursively unwraps the list, returning a list of plain Java values such
  # as Integer or String or whatever is in the list.
  #
  def unwrapped
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigValue should provide their own implementation of `unwrapped` (#{self.class})"
  end

  def with_origin(origin)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigValue should provide their own implementation of `with_origin` (#{self.class})"
  end

end
