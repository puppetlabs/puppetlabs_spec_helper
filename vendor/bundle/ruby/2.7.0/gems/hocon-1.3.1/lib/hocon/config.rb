# encoding: utf-8

require 'hocon'
require 'hocon/config_mergeable'
require 'hocon/config_error'

#
# An immutable map from config paths to config values. Paths are dot-separated
# expressions such as <code>foo.bar.baz</code>. Values are as in JSON
# (booleans, strings, numbers, lists, or objects), represented by
# {@link ConfigValue} instances. Values accessed through the
# <code>Config</code> interface are never null.
#
# <p>
# {@code Config} is an immutable object and thus safe to use from multiple
# threads. There's never a need for "defensive copies."
#
# <p>
# Fundamental operations on a {@code Config} include getting configuration
# values, <em>resolving</em> substitutions with {@link Config#resolve()}, and
# merging configs using {@link Config#withFallback(ConfigMergeable)}.
#
# <p>
# All operations return a new immutable {@code Config} rather than modifying
# the original instance.
#
# <p>
# <strong>Examples</strong>
#
# <p>
# You can find an example app and library <a
# href="https://github.com/typesafehub/config/tree/master/examples">on
# GitHub</a>. Also be sure to read the <a
# href="package-summary.html#package_description">package overview</a> which
# describes the big picture as shown in those examples.
#
# <p>
# <strong>Paths, keys, and Config vs. ConfigObject</strong>
#
# <p>
# <code>Config</code> is a view onto a tree of {@link ConfigObject}; the
# corresponding object tree can be found through {@link Config#root()}.
# <code>ConfigObject</code> is a map from config <em>keys</em>, rather than
# paths, to config values. Think of <code>ConfigObject</code> as a JSON object
# and <code>Config</code> as a configuration API.
#
# <p>
# The API tries to consistently use the terms "key" and "path." A key is a key
# in a JSON object; it's just a string that's the key in a map. A "path" is a
# parseable expression with a syntax and it refers to a series of keys. Path
# expressions are described in the <a
# href="https://github.com/typesafehub/config/blob/master/HOCON.md">spec for
# Human-Optimized Config Object Notation</a>. In brief, a path is
# period-separated so "a.b.c" looks for key c in object b in object a in the
# root object. Sometimes double quotes are needed around special characters in
# path expressions.
#
# <p>
# The API for a {@code Config} is in terms of path expressions, while the API
# for a {@code ConfigObject} is in terms of keys. Conceptually, {@code Config}
# is a one-level map from <em>paths</em> to values, while a
# {@code ConfigObject} is a tree of nested maps from <em>keys</em> to values.
#
# <p>
# Use {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath} to convert
# between path expressions and individual path elements (keys).
#
# <p>
# Another difference between {@code Config} and {@code ConfigObject} is that
# conceptually, {@code ConfigValue}s with a {@link ConfigValue#valueType()
# valueType()} of {@link ConfigValueType#NULL NULL} exist in a
# {@code ConfigObject}, while a {@code Config} treats null values as if they
# were missing.
#
# <p>
# <strong>Getting configuration values</strong>
#
# <p>
# The "getters" on a {@code Config} all work in the same way. They never return
# null, nor do they return a {@code ConfigValue} with
# {@link ConfigValue#valueType() valueType()} of {@link ConfigValueType#NULL
# NULL}. Instead, they throw {@link ConfigException.Missing} if the value is
# completely absent or set to null. If the value is set to null, a subtype of
# {@code ConfigException.Missing} called {@link ConfigException.Null} will be
# thrown. {@link ConfigException.WrongType} will be thrown anytime you ask for
# a type and the value has an incompatible type. Reasonable type conversions
# are performed for you though.
#
# <p>
# <strong>Iteration</strong>
#
# <p>
# If you want to iterate over the contents of a {@code Config}, you can get its
# {@code ConfigObject} with {@link #root()}, and then iterate over the
# {@code ConfigObject} (which implements <code>java.util.Map</code>). Or, you
# can use {@link #entrySet()} which recurses the object tree for you and builds
# up a <code>Set</code> of all path-value pairs where the value is not null.
#
# <p>
# <strong>Resolving substitutions</strong>
#
# <p>
# <em>Substitutions</em> are the <code>${foo.bar}</code> syntax in config
# files, described in the <a href=
# "https://github.com/typesafehub/config/blob/master/HOCON.md#substitutions"
# >specification</a>. Resolving substitutions replaces these references with real
# values.
#
# <p>
# Before using a {@code Config} it's necessary to call {@link Config#resolve()}
# to handle substitutions (though {@link ConfigFactory#load()} and similar
# methods will do the resolve for you already).
#
# <p>
# <strong>Merging</strong>
#
# <p>
# The full <code>Config</code> for your application can be constructed using
# the associative operation {@link Config#withFallback(ConfigMergeable)}. If
# you use {@link ConfigFactory#load()} (recommended), it merges system
# properties over the top of <code>application.conf</code> over the top of
# <code>reference.conf</code>, using <code>withFallback</code>. You can add in
# additional sources of configuration in the same way (usually, custom layers
# should go either just above or just below <code>application.conf</code>,
# keeping <code>reference.conf</code> at the bottom and system properties at
# the top).
#
# <p>
# <strong>Serialization</strong>
#
# <p>
# Convert a <code>Config</code> to a JSON or HOCON string by calling
# {@link ConfigObject#render()} on the root object,
# <code>myConfig.root().render()</code>. There's also a variant
# {@link ConfigObject#render(ConfigRenderOptions)} which allows you to control
# the format of the rendered string. (See {@link ConfigRenderOptions}.) Note
# that <code>Config</code> does not remember the formatting of the original
# file, so if you load, modify, and re-save a config file, it will be
# substantially reformatted.
#
# <p>
# As an alternative to {@link ConfigObject#render()}, the
# <code>toString()</code> method produces a debug-output-oriented
# representation (which is not valid JSON).
#
# <p>
# Java serialization is supported as well for <code>Config</code> and all
# subtypes of <code>ConfigValue</code>.
#
# <p>
# <strong>This is an interface but don't implement it yourself</strong>
#
# <p>
# <em>Do not implement {@code Config}</em>; it should only be implemented by
# the config library. Arbitrary implementations will not work because the
# library internals assume a specific concrete implementation. Also, this
# interface is likely to grow new methods over time, so third-party
# implementations will break.
#
class Config < Hocon::ConfigMergeable
  #
  # Gets the {@code Config} as a tree of {@link ConfigObject}. This is a
  # constant-time operation (it is not proportional to the number of values
  # in the {@code Config}).
  #
  # @return the root object in the configuration
  #
  def root
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `root` (#{self.class})"
  end

  #
  # Gets the origin of the {@code Config}, which may be a file, or a file
  # with a line number, or just a descriptive phrase.
  #
  # @return the origin of the {@code Config} for use in error messages
  #
  def origin
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `origin` (#{self.class})"
  end

  def with_fallback(other)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `with_fallback` (#{self.class})"
  end

  #
  # Returns a replacement config with all substitutions (the
  # <code>${foo.bar}</code> syntax, see <a
  # href="https://github.com/typesafehub/config/blob/master/HOCON.md">the
  # spec</a>) resolved. Substitutions are looked up using this
  # <code>Config</code> as the root object, that is, a substitution
  # <code>${foo.bar}</code> will be replaced with the result of
  # <code>getValue("foo.bar")</code>.
  #
  # <p>
  # This method uses {@link ConfigResolveOptions#defaults()}, there is
  # another variant {@link Config#resolve(ConfigResolveOptions)} which lets
  # you specify non-default options.
  #
  # <p>
  # A given {@link Config} must be resolved before using it to retrieve
  # config values, but ideally should be resolved one time for your entire
  # stack of fallbacks (see {@link Config#withFallback}). Otherwise, some
  # substitutions that could have resolved with all fallbacks available may
  # not resolve, which will be potentially confusing for your application's
  # users.
  #
  # <p>
  # <code>resolve()</code> should be invoked on root config objects, rather
  # than on a subtree (a subtree is the result of something like
  # <code>config.getConfig("foo")</code>). The problem with
  # <code>resolve()</code> on a subtree is that substitutions are relative to
  # the root of the config and the subtree will have no way to get values
  # from the root. For example, if you did
  # <code>config.getConfig("foo").resolve()</code> on the below config file,
  # it would not work:
  #
  # <pre>
  #   common-value = 10
  #   foo {
  #      whatever = ${common-value}
  #   }
  # </pre>
  #
  # <p>
  # Many methods on {@link ConfigFactory} such as
  # {@link ConfigFactory#load()} automatically resolve the loaded
  # <code>Config</code> on the loaded stack of config files.
  #
  # <p>
  # Resolving an already-resolved config is a harmless no-op, but again, it
  # is best to resolve an entire stack of fallbacks (such as all your config
  # files combined) rather than resolving each one individually.
  #
  # @return an immutable object with substitutions resolved
  # @throws ConfigException.UnresolvedSubstitution
  #             if any substitutions refer to nonexistent paths
  # @throws ConfigException
  #             some other config exception if there are other problems
  #
  def resolve(options)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `resolve` (#{self.class})"
  end

  #
  # Checks whether the config is completely resolved. After a successful call
  # to {@link Config#resolve()} it will be completely resolved, but after
  # calling {@link Config#resolve(ConfigResolveOptions)} with
  # <code>allowUnresolved</code> set in the options, it may or may not be
  # completely resolved. A newly-loaded config may or may not be completely
  # resolved depending on whether there were substitutions present in the
  # file.
  #
  # @return true if there are no unresolved substitutions remaining in this
  #         configuration.
  # @since 1.2.0
  #
  def resolved?
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `resolved?` (#{self.class})"
  end

  #
  # Like {@link Config#resolveWith(Config)} but allows you to specify
  # non-default options.
  #
  # @param source
  #            source configuration to pull values from
  # @param options
  #            resolve options
  # @return the resolved <code>Config</code> (may be only partially resolved
  #         if options are set to allow unresolved)
  # @since 1.2.0
  #
  def resolve_with(source, options)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `resolve_with` (#{self.class})"
  end

  #
  # Validates this config against a reference config, throwing an exception
  # if it is invalid. The purpose of this method is to "fail early" with a
  # comprehensive list of problems; in general, anything this method can find
  # would be detected later when trying to use the config, but it's often
  # more user-friendly to fail right away when loading the config.
  #
  # <p>
  # Using this method is always optional, since you can "fail late" instead.
  #
  # <p>
  # You must restrict validation to paths you "own" (those whose meaning are
  # defined by your code module). If you validate globally, you may trigger
  # errors about paths that happen to be in the config but have nothing to do
  # with your module. It's best to allow the modules owning those paths to
  # validate them. Also, if every module validates only its own stuff, there
  # isn't as much redundant work being done.
  #
  # <p>
  # If no paths are specified in <code>checkValid()</code>'s parameter list,
  # validation is for the entire config.
  #
  # <p>
  # If you specify paths that are not in the reference config, those paths
  # are ignored. (There's nothing to validate.)
  #
  # <p>
  # Here's what validation involves:
  #
  # <ul>
  # <li>All paths found in the reference config must be present in this
  # config or an exception will be thrown.
  # <li>
  # Some changes in type from the reference config to this config will cause
  # an exception to be thrown. Not all potential type problems are detected,
  # in particular it's assumed that strings are compatible with everything
  # except objects and lists. This is because string types are often "really"
  # some other type (system properties always start out as strings, or a
  # string like "5ms" could be used with {@link #getMilliseconds}). Also,
  # it's allowed to set any type to null or override null with any type.
  # <li>
  # Any unresolved substitutions in this config will cause a validation
  # failure; both the reference config and this config should be resolved
  # before validation. If the reference config is unresolved, it's a bug in
  # the caller of this method.
  # </ul>
  #
  # <p>
  # If you want to allow a certain setting to have a flexible type (or
  # otherwise want validation to be looser for some settings), you could
  # either remove the problematic setting from the reference config provided
  # to this method, or you could intercept the validation exception and
  # screen out certain problems. Of course, this will only work if all other
  # callers of this method are careful to restrict validation to their own
  # paths, as they should be.
  #
  # <p>
  # If validation fails, the thrown exception contains a list of all problems
  # found. See {@link ConfigException.ValidationFailed#problems}. The
  # exception's <code>getMessage()</code> will have all the problems
  # concatenated into one huge string, as well.
  #
  # <p>
  # Again, <code>checkValid()</code> can't guess every domain-specific way a
  # setting can be invalid, so some problems may arise later when attempting
  # to use the config. <code>checkValid()</code> is limited to reporting
  # generic, but common, problems such as missing settings and blatant type
  # incompatibilities.
  #
  # @param reference
  #            a reference configuration
  # @param restrictToPaths
  #            only validate values underneath these paths that your code
  #            module owns and understands
  # @throws ConfigException.ValidationFailed
  #             if there are any validation issues
  # @throws ConfigException.NotResolved
  #             if this config is not resolved
  # @throws ConfigException.BugOrBroken
  #             if the reference config is unresolved or caller otherwise
  #             misuses the API
  #
  def check_valid(reference, restrict_to_paths)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `check_valid` (#{self.class})"
  end

  #
  # Checks whether a value is present and non-null at the given path. This
  # differs in two ways from {@code Map.containsKey()} as implemented by
  # {@link ConfigObject}: it looks for a path expression, not a key; and it
  # returns false for null values, while {@code containsKey()} returns true
  # indicating that the object contains a null value for the key.
  #
  # <p>
  # If a path exists according to {@link #hasPath(String)}, then
  # {@link #getValue(String)} will never throw an exception. However, the
  # typed getters, such as {@link #getInt(String)}, will still throw if the
  # value is not convertible to the requested type.
  #
  # <p>
  # Note that path expressions have a syntax and sometimes require quoting
  # (see {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath}).
  #
  # @param path
  #            the path expression
  # @return true if a non-null value is present at the path
  # @throws ConfigException.BadPath
  #             if the path expression is invalid
  #
  def has_path(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `has_path` (#{self.class})"
  end

  #
  # Returns true if the {@code Config}'s root object contains no key-value
  # pairs.
  #
  # @return true if the configuration is empty
  #
  def empty?
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `empty` (#{self.class})"
  end

  #
  # Returns the set of path-value pairs, excluding any null values, found by
  # recursing {@link #root() the root object}. Note that this is very
  # different from <code>root().entrySet()</code> which returns the set of
  # immediate-child keys in the root object and includes null values.
  # <p>
  # Entries contain <em>path expressions</em> meaning there may be quoting
  # and escaping involved. Parse path expressions with
  # {@link ConfigUtil#splitPath}.
  # <p>
  # Because a <code>Config</code> is conceptually a single-level map from
  # paths to values, there will not be any {@link ConfigObject} values in the
  # entries (that is, all entries represent leaf nodes). Use
  # {@link ConfigObject} rather than <code>Config</code> if you want a tree.
  # (OK, this is a slight lie: <code>Config</code> entries may contain
  # {@link ConfigList} and the lists may contain objects. But no objects are
  # directly included as entry values.)
  #
  # @return set of paths with non-null values, built up by recursing the
  #         entire tree of {@link ConfigObject} and creating an entry for
  #         each leaf value.
  #
  def entry_set
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `entry_set` (#{self.class})"
  end

  #
  #
  # @param path
  #            path expression
  # @return the boolean value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to boolean
  #
  def get_boolean(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_boolean` (#{self.class})"
  end

  #
  # @param path
  #            path expression
  # @return the numeric value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a number
  #
  def get_number(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_number` (#{self.class})"
  end

  #
  # Gets the integer at the given path. If the value at the
  # path has a fractional (floating point) component, it
  # will be discarded and only the integer part will be
  # returned (it works like a "narrowing primitive conversion"
  # in the Java language specification).
  #
  # @param path
  #            path expression
  # @return the 32-bit integer value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to an int (for example it is out
  #             of range, or it's a boolean value)
  #
  def get_int(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_int` (#{self.class})"
  end


  #
  # Gets the long integer at the given path.  If the value at
  # the path has a fractional (floating point) component, it
  # will be discarded and only the integer part will be
  # returned (it works like a "narrowing primitive conversion"
  # in the Java language specification).
  #
  # @param path
  #            path expression
  # @return the 64-bit long value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a long
  #
  def get_long(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_long` (#{self.class})"
  end

  #
  # @param path
  #            path expression
  # @return the floating-point value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a double
  #
  def get_double(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_double` (#{self.class})"
  end

  #
  # @param path
  #            path expression
  # @return the string value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a string
  #
  def get_string(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_string` (#{self.class})"
  end

  #
  # @param path
  #            path expression
  # @return the {@link ConfigObject} value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to an object
  #
  def get_object(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_object` (#{self.class})"
  end

  #
  # @param path
  #            path expression
  # @return the nested {@code Config} value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a Config
  #
  def get_config(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_config` (#{self.class})"
  end

  #
  # Gets the value at the path as an unwrapped Java boxed value (
  # {@link java.lang.Boolean Boolean}, {@link java.lang.Integer Integer}, and
  # so on - see {@link ConfigValue#unwrapped()}).
  #
  # @param path
  #            path expression
  # @return the unwrapped value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  #
  def get_any_ref(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_any_ref` (#{self.class})"
  end

  #
  # Gets the value at the given path, unless the value is a
  # null value or missing, in which case it throws just like
  # the other getters. Use {@code get()} on the {@link
  # Config#root()} object (or other object in the tree) if you
  # want an unprocessed value.
  #
  # @param path
  #            path expression
  # @return the value at the requested path
  # @throws ConfigException.Missing
  #             if value is absent or null
  #
  def get_value(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_value`path(#{self.class})"
  end

  #
  # Gets a value as a size in bytes (parses special strings like "128M"). If
  # the value is already a number, then it's left alone; if it's a string,
  # it's parsed understanding unit suffixes such as "128K", as documented in
  # the <a
  # href="https://github.com/typesafehub/config/blob/master/HOCON.md">the
  # spec</a>.
  #
  # @param path
  #            path expression
  # @return the value at the requested path, in bytes
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to Long or String
  # @throws ConfigException.BadValue
  #             if value cannot be parsed as a size in bytes
  #
  def get_bytes(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_bytes` (#{self.class})"
  end

  #
  # Gets a value as an amount of memory (parses special strings like "128M"). If
  # the value is already a number, then it's left alone; if it's a string,
  # it's parsed understanding unit suffixes such as "128K", as documented in
  # the <a
  # href="https://github.com/typesafehub/config/blob/master/HOCON.md">the
  # spec</a>.
  #
  # @since 1.3.0
  #
  # @param path
  #            path expression
  # @return the value at the requested path, in bytes
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to Long or String
  # @throws ConfigException.BadValue
  #             if value cannot be parsed as a size in bytes
  #
  def get_memory_size(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_memory_size`path(#{self.class})"
  end

  #
  # Get value as a duration in milliseconds. If the value is already a
  # number, then it's left alone; if it's a string, it's parsed understanding
  # units suffixes like "10m" or "5ns" as documented in the <a
  # href="https://github.com/typesafehub/config/blob/master/HOCON.md">the
  # spec</a>.
  #
  # @deprecated  As of release 1.1, replaced by {@link #getDuration(String, TimeUnit)}
  #
  # @param path
  #            path expression
  # @return the duration value at the requested path, in milliseconds
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to Long or String
  # @throws ConfigException.BadValue
  #             if value cannot be parsed as a number of milliseconds
  #
  def get_milliseconds(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_milliseconds` (#{self.class})"
  end

  #
  # Get value as a duration in nanoseconds. If the value is already a number
  # it's taken as milliseconds and converted to nanoseconds. If it's a
  # string, it's parsed understanding unit suffixes, as for
  # {@link #getDuration(String, TimeUnit)}.
  #
  # @deprecated  As of release 1.1, replaced by {@link #getDuration(String, TimeUnit)}
  #
  # @param path
  #            path expression
  # @return the duration value at the requested path, in nanoseconds
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to Long or String
  # @throws ConfigException.BadValue
  #             if value cannot be parsed as a number of nanoseconds
  #
  def get_nanoseconds(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_nanoseconds` (#{self.class})"
  end

  #
  # Gets a value as a duration in a specified
  # {@link java.util.concurrent.TimeUnit TimeUnit}. If the value is already a
  # number, then it's taken as milliseconds and then converted to the
  # requested TimeUnit; if it's a string, it's parsed understanding units
  # suffixes like "10m" or "5ns" as documented in the <a
  # href="https://github.com/typesafehub/config/blob/master/HOCON.md">the
  # spec</a>.
  #
  # @since 1.2.0
  #
  # @param path
  #            path expression
  # @param unit
  #            convert the return value to this time unit
  # @return the duration value at the requested path, in the given TimeUnit
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to Long or String
  # @throws ConfigException.BadValue
  #             if value cannot be parsed as a number of the given TimeUnit
  #
  def get_duration(path, unit)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_duration` (#{self.class})"
  end

  #
  # Gets a list value (with any element type) as a {@link ConfigList}, which
  # implements {@code java.util.List<ConfigValue>}. Throws if the path is
  # unset or null.
  #
  # @param path
  #            the path to the list value.
  # @return the {@link ConfigList} at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a ConfigList
  #
  def get_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_list` (#{self.class})"
  end

  #
  # Gets a list value with boolean elements.  Throws if the
  # path is unset or null or not a list or contains values not
  # convertible to boolean.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of booleans
  #
  def get_boolean_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_boolean_list` (#{self.class})"
  end

  #
  # Gets a list value with number elements.  Throws if the
  # path is unset or null or not a list or contains values not
  # convertible to number.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of numbers
  #
  def get_number_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_number_list` (#{self.class})"
  end

  #
  # Gets a list value with int elements.  Throws if the
  # path is unset or null or not a list or contains values not
  # convertible to int.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of ints
  #
  def get_int_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_int_list` (#{self.class})"
  end

  #
  # Gets a list value with long elements.  Throws if the
  # path is unset or null or not a list or contains values not
  # convertible to long.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of longs
  #
  def get_long_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_long_list` (#{self.class})"
  end

  #
  # Gets a list value with double elements.  Throws if the
  # path is unset or null or not a list or contains values not
  # convertible to double.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of doubles
  #
  def get_double_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_double_list` (#{self.class})"
  end

  #
  # Gets a list value with string elements.  Throws if the
  # path is unset or null or not a list or contains values not
  # convertible to string.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of strings
  #
  def get_string_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_string_list` (#{self.class})"
  end

  #
  # Gets a list value with object elements.  Throws if the
  # path is unset or null or not a list or contains values not
  # convertible to <code>ConfigObject</code>.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of objects
  #
  def get_object_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_object_list` (#{self.class})"
  end

  #
  # Gets a list value with <code>Config</code> elements.
  # Throws if the path is unset or null or not a list or
  # contains values not convertible to <code>Config</code>.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of configs
  #
  def get_config_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_config_list` (#{self.class})"
  end

  #
  # Gets a list value with any kind of elements.  Throws if the
  # path is unset or null or not a list. Each element is
  # "unwrapped" (see {@link ConfigValue#unwrapped()}).
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list
  #
  def get_any_ref_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_any_ref_list`path(#{self.class})"
  end

  #
  # Gets a list value with elements representing a size in
  # bytes.  Throws if the path is unset or null or not a list
  # or contains values not convertible to memory sizes.
  #
  # @param path
  #            the path to the list value.
  # @return the list at the path
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of memory sizes
  #
  def get_bytes_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_bytes_list` (#{self.class})"
  end

  #
  # Gets a list, converting each value in the list to a memory size, using the
  # same rules as {@link #getMemorySize(String)}.
  #
  # @since 1.3.0
  # @param path
  #            a path expression
  # @return list of memory sizes
  # @throws ConfigException.Missing
  #             if value is absent or null
  # @throws ConfigException.WrongType
  #             if value is not convertible to a list of memory sizes
  #
  def get_memory_size_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_memory_size_list` (#{self.class})"
  end

  #
  # @deprecated  As of release 1.1, replaced by {@link #getDurationList(String, TimeUnit)}
  # @param path the path
  # @return list of millisecond values
  #
  def get_milliseconds_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_milliseconds_list` (#{self.class})"
  end

  #
  # @deprecated  As of release 1.1, replaced by {@link #getDurationList(String, TimeUnit)}
  # @param path the path
  # @return list of nanosecond values
  #
  def get_nanoseconds_list(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_nanoseconds_list` (#{self.class})"
  end

  #
  # Gets a list, converting each value in the list to a duration, using the
  # same rules as {@link #getDuration(String, TimeUnit)}.
  #
  # @since 1.2.0
  # @param path
  #            a path expression
  # @param unit
  #            time units of the returned values
  # @return list of durations, in the requested units
  #
  def get_duration_list(path, unit)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `get_duration_list` (#{self.class})"
  end

  #
  # Clone the config with only the given path (and its children) retained;
  # all sibling paths are removed.
  # <p>
  # Note that path expressions have a syntax and sometimes require quoting
  # (see {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath}).
  #
  # @param path
  #            path to keep
  # @return a copy of the config minus all paths except the one specified
  #
  def with_only_path(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `with_only_path` (#{self.class})"
  end

  #
  # Clone the config with the given path removed.
  # <p>
  # Note that path expressions have a syntax and sometimes require quoting
  # (see {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath}).
  #
  # @param path
  #            path expression to remove
  # @return a copy of the config minus the specified path
  #
  def without_path(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `without_path` (#{self.class})"
  end

  #
  # Places the config inside another {@code Config} at the given path.
  # <p>
  # Note that path expressions have a syntax and sometimes require quoting
  # (see {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath}).
  #
  # @param path
  #            path expression to store this config at.
  # @return a {@code Config} instance containing this config at the given
  #         path.
  #
  def at_path(path)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `at_path` (#{self.class})"
  end

  #
  # Places the config inside a {@code Config} at the given key. See also
  # atPath(). Note that a key is NOT a path expression (see
  # {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath}).
  #
  # @param key
  #            key to store this config at.
  # @return a {@code Config} instance containing this config at the given
  #         key.
  #
  def at_key(key)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `at_key` (#{self.class})"
  end

  #
  # Returns a {@code Config} based on this one, but with the given path set
  # to the given value. Does not modify this instance (since it's immutable).
  # If the path already has a value, that value is replaced. To remove a
  # value, use withoutPath().
  # <p>
  # Note that path expressions have a syntax and sometimes require quoting
  # (see {@link ConfigUtil#joinPath} and {@link ConfigUtil#splitPath}).
  #
  # @param path
  #            path expression for the value's new location
  # @param value
  #            value at the new path
  # @return the new instance with the new map entry
  #
  def with_value(path, value)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of `Config` must implement `with_value` (#{self.class})"
  end
end

