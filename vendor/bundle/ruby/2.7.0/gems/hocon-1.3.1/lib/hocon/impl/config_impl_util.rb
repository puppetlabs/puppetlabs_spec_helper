# encoding: utf-8

require 'hocon/impl'
require 'stringio'

class Hocon::Impl::ConfigImplUtil
  def self.equals_handling_nil?(a, b)
    # This method probably doesn't make any sense in ruby... not sure
    if a.nil? && !b.nil?
      false
    elsif !a.nil? && b.nil?
      false
    # in ruby, the == and .equal? are the opposite of what they are in Java
    elsif a.equal?(b)
      true
    else
      a == b
    end
  end

  #
  # This is public ONLY for use by the "config" package, DO NOT USE this ABI
  # may change.
  #
  def self.render_json_string(s)
    sb = StringIO.new
    sb << '"'
    s.chars.each do |c|
      case c
        when '"' then sb << "\\\""
        when "\\" then sb << "\\\\"
        when "\n" then sb << "\\n"
        when "\b" then sb << "\\b"
        when "\f" then sb << "\\f"
        when "\r" then sb << "\\r"
        when "\t" then sb << "\\t"
        else
          if c =~ /[[:cntrl:]]/
            sb << ("\\u%04x" % c)
          else
            sb << c
          end
      end
    end
    sb << '"'
    sb.string
  end

  def self.render_string_unquoted_if_possible(s)
    # this can quote unnecessarily as long as it never fails to quote when
    # necessary
    if s.length == 0
      return render_json_string(s)
    end

    # if it starts with a hyphen or number, we have to quote
    # to ensure we end up with a string and not a number
    first = s.chars.first
    if (first =~ /[[:digit:]]/) || (first == '-')
      return render_json_string(s)
    end

    # only unquote if it's pure alphanumeric
    s.chars.each do |c|
      unless (c =~ /[[:alnum:]]/) || (c == '-')
        return render_json_string(s)
      end
    end

    s
  end

  def self.join_path(*elements)
    Hocon::Impl::Path.from_string_list(elements).render
  end

  def self.split_path(path)
    p = Hocon::Impl::Path.new_path(path)
    elements = []

    until p.nil?
      elements << p.first
      p = p.remainder
    end

    elements
  end

  def self.whitespace?(c)
    # this implementation is *not* a port of the java code, because it relied on
    # the method java.lang.Character#isWhitespace.  This is probably
    # insanely slow (running a regex against every single character in the
    # file).
    c =~ /[[:space:]]/
  end

  def self.unicode_trim(s)
    # this implementation is *not* a port of the java code. Ruby can strip
    # unicode whitespace much easier than Java can, and relies on a lot of
    # Java functions that don't really have straight equivalents in Ruby.
    s.gsub(/[:space]/, ' ')
    s.strip
  end
end
