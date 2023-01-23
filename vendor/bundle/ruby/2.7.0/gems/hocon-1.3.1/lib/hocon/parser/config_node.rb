# encoding: utf-8

require 'hocon/parser'
require 'hocon/config_error'

#
# An immutable node that makes up the ConfigDocument AST, and which can be
# used to reproduce part or all of the original text of an input.
#
# <p>
# Because this object is immutable, it is safe to use from multiple threads and
# there's no need for "defensive copies."
#
# <p>
# <em>Do not implement interface {@code ConfigNode}</em>; it should only be
# implemented by the config library. Arbitrary implementations will not work
# because the library internals assume a specific concrete implementation.
# Also, this interface is likely to grow new methods over time, so third-party
# implementations will break.
#

module Hocon::Parser::ConfigNode
  #
  # The original text of the input which was used to form this particular node.
  # @return the original text used to form this node as a String
  #
  def render
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigNode should override `render` (#{self.class})"
  end
end
