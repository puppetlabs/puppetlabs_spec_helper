# encoding: utf-8

require 'hocon'
require 'hocon/impl/parseable'
require 'hocon/config_parse_options'
require 'hocon/impl/config_impl'
require 'hocon/config_factory'

## Please note that the `parse` operations will simply create a ConfigValue
## and do nothing else, whereas the `load` operations will perform a higher-level
## operation and will resolve substitutions. If you have substitutions in your
## configuration, use a `load` function
class Hocon::ConfigFactory
  def self.parse_file(file_path, options = Hocon::ConfigParseOptions.defaults)
    Hocon::Impl::Parseable.new_file(file_path, options).parse.to_config
  end

  def self.parse_string(string, options = Hocon::ConfigParseOptions.defaults)
    Hocon::Impl::Parseable.new_string(string, options).parse.to_config
  end

  def self.parse_file_any_syntax(file_base_name, options)
    Hocon::Impl::ConfigImpl.parse_file_any_syntax(file_base_name, options).to_config
  end

  def self.empty(origin_description = nil)
    Hocon::Impl::ConfigImpl.empty_config(origin_description)
  end

  # Because of how optional arguments work, if either parse or resolve options is supplied
  # both must be supplied. load_file_with_parse_options or load_file_with_resolve_options
  # can be used instead, or the argument you don't care about in load_file can be nil
  #
  # e.g.:
  # load_file("settings", my_parse_options, nil)
  # is equivalent to:
  # load_file_with_parse_options("settings", my_parse_options)
  def self.load_file(file_base_name, parse_options = nil, resolve_options = nil)
    parse_options ||= Hocon::ConfigParseOptions.defaults
    resolve_options ||= Hocon::ConfigResolveOptions.defaults

    config = Hocon::ConfigFactory.parse_file_any_syntax(file_base_name, parse_options)

    self.load_from_config(config, resolve_options)
  end

  def self.load_file_with_parse_options(file_base_name, parse_options)
    self.load_file(file_base_name, parse_options, nil)
  end

  def self.load_file_with_resolve_options(file_base_name, resolve_options)
    self.load_file(file_base_name, nil, resolve_options)
  end

  def self.load_from_config(config, resolve_options)

    config.with_fallback(self.default_reference).resolve(resolve_options)
  end

  def self.default_reference
    Hocon::Impl::ConfigImpl.default_reference
  end
end
