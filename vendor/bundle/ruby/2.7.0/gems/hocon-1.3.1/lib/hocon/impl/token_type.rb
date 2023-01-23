# encoding: utf-8

require 'hocon/impl'

class Hocon::Impl::TokenType
  START = 0
  EOF = 1
  COMMA = 2
  EQUALS = 3
  COLON = 4
  OPEN_CURLY = 5
  CLOSE_CURLY = 6
  OPEN_SQUARE = 7
  CLOSE_SQUARE = 8
  VALUE = 9
  NEWLINE = 10
  UNQUOTED_TEXT = 11
  SUBSTITUTION = 12
  PROBLEM = 13
  COMMENT = 14
  PLUS_EQUALS = 15
  IGNORED_WHITESPACE = 16

  def self.token_type_name(token_type)
    case token_type
      when START then "START"
      when EOF then "EOF"
      when COMMA then "COMMA"
      when EQUALS then "EQUALS"
      when COLON then "COLON"
      when OPEN_CURLY then "OPEN_CURLY"
      when CLOSE_CURLY then "CLOSE_CURLY"
      when OPEN_SQUARE then "OPEN_SQUARE"
      when CLOSE_SQUARE then "CLOSE_SQUARE"
      when VALUE then "VALUE"
      when NEWLINE then "NEWLINE"
      when UNQUOTED_TEXT then "UNQUOTED_TEXT"
      when SUBSTITUTION then "SUBSTITUTION"
      when PROBLEM then "PROBLEM"
      when COMMENT then "COMMENT"
      when PLUS_EQUALS then "PLUS_EQUALS"
      when IGNORED_WHITESPACE then "IGNORED_WHITESPACE"
      else raise ConfigBugOrBrokenError, "Unrecognized token type #{token_type}"
    end
  end
end
