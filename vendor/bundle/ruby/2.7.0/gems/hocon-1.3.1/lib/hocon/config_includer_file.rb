# encoding: utf-8

require 'hocon'
require 'hocon/config_error'

#
# Implement this <em>in addition to</em> {@link ConfigIncluder} if you want to
# support inclusion of files with the {@code include file("filename")} syntax.
# If you do not implement this but do implement {@link ConfigIncluder},
# attempts to load files will use the default includer.
#
module Hocon::ConfigIncluderFile
  #
  # Parses another item to be included. The returned object typically would
  # not have substitutions resolved. You can throw a ConfigException here to
  # abort parsing, or return an empty object, but may not return null.
  #
  # @param context
  #            some info about the include context
  # @param what
  #            the include statement's argument
  # @return a non-null ConfigObject
  #
  def include_file(context, what)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `ConfigIncluderFile` must implement `include_file` (#{self.class})"
  end
end
