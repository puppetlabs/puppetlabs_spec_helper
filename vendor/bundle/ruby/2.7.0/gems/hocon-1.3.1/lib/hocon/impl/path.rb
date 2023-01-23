# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/path_builder'
require 'hocon/config_error'
require 'stringio'

class Hocon::Impl::Path

  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigImplUtil = Hocon::Impl::ConfigImplUtil

  def initialize(first, remainder)
    # first: String, remainder: Path

    @first = first
    @remainder = remainder
  end
  attr_reader :first, :remainder

  def self.from_string_list(elements)
    # This method was translated from the Path constructor in the
    # Java hocon library that has this signature:
    #   Path(String... elements)
    #
    # It figures out what @first and @remainder should be, then
    # pass those to the ruby constructor
    if elements.length == 0
      raise Hocon::ConfigError::ConfigBugOrBrokenError.new("empty path")
    end

    new_first = elements.first

    if elements.length > 1
      pb = Hocon::Impl::PathBuilder.new

      # Skip first element
      elements.drop(1).each do |element|
        pb.append_key(element)
      end

      new_remainder = pb.result
    else
      new_remainder = nil
    end

    self.new(new_first, new_remainder)
  end

  def self.from_path_list(path_list)
    # This method was translated from the Path constructors in the
    # Java hocon library that take in a list of Paths
    #
    # It just passes an iterator to self.from_path_iterator, which
    # will return a new Path object
    from_path_iterator(path_list.each)
  end

  def self.from_path_iterator(path_iterator)
    # This method was translated from the Path constructors in the
    # Java hocon library that takes in an iterator of Paths
    #
    # It figures out what @first and @remainder should be, then
    # pass those to the ruby constructor

    # Try to get first path from iterator
    # Ruby iterators have no .hasNext() method like java
    # So we try to catch the StopIteration exception
    begin
      first_path = path_iterator.next
    rescue StopIteration
      raise Hocon::ConfigError::ConfigBugOrBrokenError("empty path")
    end

    new_first = first_path.first

    pb = Hocon::Impl::PathBuilder.new

    unless first_path.remainder.nil?
      pb.append_path(first_path.remainder)
    end

    # Skip first path
    path_iterator.drop(1).each do |path|
      pb.append_path(path)
    end

    new_remainder = pb.result

    self.new(new_first, new_remainder)
  end

  def first
    @first
  end

  def remainder
    @remainder
  end

  def parent
    if remainder.nil?
      return nil
    end

    pb = Hocon::Impl::PathBuilder.new
    p = self
    while not p.remainder.nil?
      pb.append_key(p.first)
      p = p.remainder
    end
    pb.result
  end

  def last
    p = self
    while p.remainder != nil
      p = p.remainder
    end
    p.first
  end

  def prepend(to_prepend)
    pb = Hocon::Impl::PathBuilder.new

    pb.append_path(to_prepend)
    pb.append_path(self)

    pb.result
  end

  def length
    count = 1
    p = remainder
    while p != nil do
      count += 1
      p = p.remainder
    end
    count
  end

  def sub_path(first_index, last_index)
    if last_index < first_index
      raise ConfigBugOrBrokenError.new("bad call to sub_path")
    end
    from = sub_path_to_end(first_index)
    pb = Hocon::Impl::PathBuilder.new
    count = last_index - first_index
    while count > 0 do
      count -= 1
      pb.append_key(from.first)
      from = from.remainder
      if from.nil?
        raise ConfigBugOrBrokenError.new("sub_path last_index out of range #{last_index}")
      end
    end
    pb.result
  end

  # translated from `subPath(int removeFromFront)` upstream
  def sub_path_to_end(remove_from_front)
    count = remove_from_front
    p = self
    while (not p.nil?) && count > 0 do
      count -= 1
      p = p.remainder
    end
    p
  end

  def starts_with(other)
    my_remainder = self
    other_remainder = other
    if other_remainder.length <= my_remainder.length
      while ! other_remainder.nil?
        if ! (other_remainder.first == my_remainder.first)
          return false
        end
        my_remainder = my_remainder.remainder
        other_remainder = other_remainder.remainder
      end
      return true
    end
    false
  end

  def ==(other)
    if other.is_a? Hocon::Impl::Path
      that = other
      first == that.first && ConfigImplUtil.equals_handling_nil?(remainder, that.remainder)
    else
      false
    end
  end

  def hash
    remainder_hash = remainder.nil? ? 0 : remainder.hash

    41 * (41 + first.hash) + remainder_hash
  end

  # this doesn't have a very precise meaning, just to reduce
  # noise from quotes in the rendered path for average cases
  def self.has_funky_chars?(s)
    length = s.length
    if length == 0
      return false
    end

    s.chars.each do |c|
      unless (c =~ /[[:alnum:]]/) || (c == '-') || (c == '_')
        return true
      end
    end

    false
  end

  def append_to_string_builder(sb)
    if self.class.has_funky_chars?(@first) || @first.empty?
      sb << ConfigImplUtil.render_json_string(@first)
    else
      sb << @first
    end

    unless @remainder.nil?
      sb << "."
      @remainder.append_to_string_builder(sb)
    end
  end

  def to_s
    sb = StringIO.new
    sb << "Path("
    append_to_string_builder(sb)
    sb << ")"

    sb.string
  end

  def inspect
    to_s
  end

  #
  # toString() is a debugging-oriented version while this is an
  # error-message-oriented human-readable one.
  #
  def render
    sb = StringIO.new
    append_to_string_builder(sb)
    sb.string
  end

  def self.new_key(key)
    return self.new(key, nil)
  end

  def self.new_path(path)
    Hocon::Impl::PathParser.parse_path(path)
  end

end
