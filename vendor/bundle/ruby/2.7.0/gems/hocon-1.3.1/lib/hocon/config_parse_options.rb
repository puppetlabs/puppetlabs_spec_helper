# encoding: utf-8

require 'hocon'

class Hocon::ConfigParseOptions
  attr_accessor :syntax, :origin_description, :allow_missing, :includer

  def self.defaults
    self.new(nil, nil, true, nil)
  end

  def initialize(syntax, origin_description, allow_missing, includer)
    @syntax = syntax
    @origin_description = origin_description
    @allow_missing = allow_missing
    @includer = includer
  end

  def set_syntax(syntax)
    if @syntax == syntax
      self
    else
      Hocon::ConfigParseOptions.new(syntax,
                                    @origin_description,
                                    @allow_missing,
                                    @includer)
    end
  end

  def set_origin_description(origin_description)
    if @origin_description == origin_description
      self
    else
      Hocon::ConfigParseOptions.new(@syntax,
                                    origin_description,
                                    @allow_missing,
                                    @includer)
    end
  end

  def set_allow_missing(allow_missing)
    if allow_missing? == allow_missing
      self
    else
      Hocon::ConfigParseOptions.new(@syntax,
                                    @origin_description,
                                    allow_missing,
                                    @includer)
    end
  end

  def allow_missing?
    @allow_missing
  end

  def set_includer(includer)
    if @includer == includer
      self
    else
      Hocon::ConfigParseOptions.new(@syntax,
                                    @origin_description,
                                    @allow_missing,
                                    includer)
    end
  end

  def append_includer(includer)
    if @includer == includer
      self
    elsif @includer
      set_includer(@includer.with_fallback(includer))
    else
      set_includer(includer)
    end
  end

end
