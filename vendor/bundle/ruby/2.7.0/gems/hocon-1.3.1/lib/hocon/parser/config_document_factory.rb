# encoding: utf-8

require 'hocon/parser'
require 'hocon/impl/parseable'
require 'hocon/config_parse_options'

#
# Factory for creating {@link
# com.typesafe.config.parser.ConfigDocument} instances.
#
class Hocon::Parser::ConfigDocumentFactory
  #
  # Parses a file into a ConfigDocument instance.
  #
  # @param file
  #       the file to parse
  # @param options
  #       parse options to control how the file is interpreted
  # @return the parsed configuration
  # @throws com.typesafe.config.ConfigException on IO or parse errors
  #
  def self.parse_file(file, options = Hocon::ConfigParseOptions.defaults)
    Hocon::Impl::Parseable.new_file(file, options).parse_config_document
  end

  #
  # Parses a string which should be valid HOCON or JSON.
  #
  # @param s string to parse
  # @param options parse options
  # @return the parsed configuration
  #
  def self.parse_string(s, options = Hocon::ConfigParseOptions.defaults)
    Hocon::Impl::Parseable.new_string(s, options).parse_config_document
  end
end