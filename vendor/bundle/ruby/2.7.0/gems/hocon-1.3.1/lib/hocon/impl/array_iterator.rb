# encoding: utf-8

require 'hocon/impl'

class Hocon::Impl::ArrayIterator
  def initialize(a)
    @a = a
    @index = 0
  end

  def has_next?
    @index < @a.length
  end

  def next
    @index += 1
    @a[@index - 1]
  end
end
