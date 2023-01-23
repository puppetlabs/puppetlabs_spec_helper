# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/token_type'

class Hocon::Impl::Token
  attr_reader :token_type, :token_text
  def self.new_without_origin(token_type, debug_string, token_text)
    Hocon::Impl::Token.new(token_type, nil, token_text, debug_string)
  end

  def initialize(token_type, origin, token_text = nil, debug_string = nil)
    @token_type = token_type
    @origin = origin
    @token_text = token_text
    @debug_string = debug_string
  end

  attr_reader :origin

  def line_number
    if @origin
      @origin.line_number
    else
      -1
    end
  end

  def to_s
    if !@debug_string.nil?
      @debug_string
    else
      Hocon::Impl::TokenType.token_type_name(@token_type)
    end
  end

  def ==(other)
    # @origin deliberately left out
    other.is_a?(Hocon::Impl::Token) && @token_type == other.token_type
  end

  def hash
    @token_type.hash
  end
end
