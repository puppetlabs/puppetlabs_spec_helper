# encoding: utf-8

module Hocon
  # NOTE: the behavior of this load method differs a bit from the upstream public
  # API, where a file extension may be the preferred method of determining
  # the config syntax, even if you specify a Syntax value on ConfigParseOptions.
  # Here we prefer the syntax (optionally) specified by the user no matter what
  # the file extension is, and if they don't specify one and the file extension
  # is unrecognized, we raise an error.
  def self.load(file, opts = nil)
    # doing these requires lazily, because otherwise, classes that need to
    # `require 'hocon'` to get the module into scope will end up recursing
    # through this require and probably ending up with circular dependencies.
    require 'hocon/config_factory'
    require 'hocon/impl/parseable'
    require 'hocon/config_parse_options'
    require 'hocon/config_resolve_options'
    require 'hocon/config_error'
    syntax = opts ? opts[:syntax] : nil

    if syntax.nil?
      unless Hocon::Impl::Parseable.syntax_from_extension(file)
        raise Hocon::ConfigError::ConfigParseError.new(
            nil, "Unrecognized file extension '#{File.extname(file)}' and no value provided for :syntax option", nil)
      end
      config = Hocon::ConfigFactory.parse_file_any_syntax(
          file, Hocon::ConfigParseOptions.defaults)
    else
      config = Hocon::ConfigFactory.parse_file(
          file, Hocon::ConfigParseOptions.defaults.set_syntax(syntax))
    end

    resolved_config = Hocon::ConfigFactory.load_from_config(
        config, Hocon::ConfigResolveOptions.defaults)

    resolved_config.root.unwrapped
  end

  def self.parse(string)
    # doing these requires lazily, because otherwise, classes that need to
    # `require 'hocon'` to get the module into scope will end up recursing
    # through this require and probably ending up with circular dependencies.
    require 'hocon/config_factory'
    require 'hocon/config_resolve_options'
    config = Hocon::ConfigFactory.parse_string(string)
    resolved_config = Hocon::ConfigFactory.load_from_config(
        config, Hocon::ConfigResolveOptions.defaults)

    resolved_config.root.unwrapped
  end
end
