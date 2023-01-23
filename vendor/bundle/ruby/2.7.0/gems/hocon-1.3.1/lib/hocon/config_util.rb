require 'hocon/impl/config_impl_util'


# Contains static utility methods
class Hocon::ConfigUtil
  #
  # Quotes and escapes a string, as in the JSON specification.
  #
  # @param string
  #            a string
  # @return the string quoted and escaped
  #
  def self.quote_string(string)
    Hocon::Impl::ConfigImplUtil.render_json_string(string)
  end

  #
  # Converts a list of keys to a path expression, by quoting the path
  # elements as needed and then joining them separated by a period. A path
  # expression is usable with a {@link Config}, while individual path
  # elements are usable with a {@link ConfigObject}.
  # <p>
  # See the overview documentation for {@link Config} for more detail on path
  # expressions vs. keys.
  #
  # @param elements
  #            the keys in the path
  # @return a path expression
  # @throws ConfigException
  #             if there are no elements
  #
  def self.join_path(*elements)
    Hocon::Impl::ConfigImplUtil.join_path(*elements)
  end

  #
  # Converts a list of strings to a path expression, by quoting the path
  # elements as needed and then joining them separated by a period. A path
  # expression is usable with a {@link Config}, while individual path
  # elements are usable with a {@link ConfigObject}.
  # <p>
  # See the overview documentation for {@link Config} for more detail on path
  # expressions vs. keys.
  #
  # @param elements
  #            the keys in the path
  # @return a path expression
  # @throws ConfigException
  #             if the list is empty
  #
  def self.join_path_from_list(elements)
    self.join_path(*elements)
  end

  #
  # Converts a path expression into a list of keys, by splitting on period
  # and unquoting the individual path elements. A path expression is usable
  # with a {@link Config}, while individual path elements are usable with a
  # {@link ConfigObject}.
  # <p>
  # See the overview documentation for {@link Config} for more detail on path
  # expressions vs. keys.
  #
  # @param path
  #            a path expression
  # @return the individual keys in the path
  # @throws ConfigException
  #             if the path expression is invalid
  #
  def self.split_path(path)
    Hocon::Impl::ConfigImplUtil.split_path(path)
  end
end
