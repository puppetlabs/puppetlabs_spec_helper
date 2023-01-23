# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/path'
require 'hocon/config_error'

class Hocon::Impl::PathBuilder

  def initialize
    @keys = []
    @result = nil
  end

  def check_can_append
    if @result
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "Adding to PathBuilder after getting result"
    end
  end

  def append_key(key)
    check_can_append
    @keys.push(key)
  end

  def append_path(path)
    check_can_append

    first = path.first
    remainder = path.remainder

    loop do
      @keys.push(first)

      if !remainder.nil?
        first = remainder.first
        remainder = remainder.remainder
      else
        break
      end
    end
  end

  def result
    # note: if keys is empty, we want to return nil, which is a valid
    # empty path
    if @result.nil?
      remainder = nil
      while !@keys.empty?
        key = @keys.pop
        remainder = Hocon::Impl::Path.new(key, remainder)
      end
      @result = remainder
    end
    @result
  end
end
