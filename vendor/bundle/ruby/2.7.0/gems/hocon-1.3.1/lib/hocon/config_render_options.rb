# encoding: utf-8

require 'hocon'

class Hocon::ConfigRenderOptions
  def initialize(origin_comments, comments, formatted, json, key_value_separator=:equals)
    @origin_comments = origin_comments
    @comments = comments
    @formatted = formatted
    @json = json
    @key_value_separator = key_value_separator
  end

  attr_accessor :origin_comments, :comments, :formatted, :json, :key_value_separator

  def origin_comments?
    @origin_comments
  end
  def comments?
    @comments
  end
  def formatted?
    @formatted
  end
  def json?
    @json
  end

  #
  # Returns the default render options which are verbose (commented and
  # formatted). See {@link ConfigRenderOptions#concise} for stripped-down
  # options. This rendering will not be valid JSON since it has comments.
  #
  # @return the default render options
  #
  def self.defaults
    Hocon::ConfigRenderOptions.new(true, true, true, true)
  end

  #
  # Returns concise render options (no whitespace or comments). For a
  # resolved {@link Config}, the concise rendering will be valid JSON.
  #
  # @return the concise render options
  #
  def self.concise
    Hocon::ConfigRenderOptions.new(false, false, false, true)
  end
end
