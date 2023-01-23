# encoding: utf-8

require 'hocon'
require 'hocon/impl'

class Hocon::Impl::MemoKey

  def initialize(value, restrict_to_child_or_nil)
    @value = value
    @restrict_to_child_or_nil = restrict_to_child_or_nil
  end

  def hash
    h = @value.hash
    if @restrict_to_child_or_nil != nil
      h + 41 * (41 + @restrict_to_child_or_nil.hash)
    else
      h
    end
  end

  def ==(other)
    if other.is_a?(self.class)
      o = other
      if !o.value.equal?(@value)
        return false
      elsif o.restrict_to_child_or_nil.equals(@restrict_to_child_or_nil)
        return true
      elsif o.restrict_to_child_or_nil == nil || @restrict_to_child_or_nil == nil
        return false
      else
        return o.restrict_to_child_or_nil == @restrict_to_child_or_nil
      end
    else
      false
    end
  end

  def to_s
    "MemoKey(#{@value}@#{@value.hash},#{@restrict_to_child_or_nil})"
  end
end
