# encoding: utf-8

require 'stringio'
require 'hocon/impl'
require 'hocon/config_syntax'
require 'hocon/impl/tokenizer'
require 'hocon/impl/config_node_path'
require 'hocon/impl/tokens'
require 'hocon/config_value_type'
require 'hocon/config_error'

class Hocon::Impl::PathParser
  ConfigSyntax = Hocon::ConfigSyntax
  SimpleConfigOrigin = Hocon::Impl::SimpleConfigOrigin
  Tokenizer = Hocon::Impl::Tokenizer
  Tokens = Hocon::Impl::Tokens
  ConfigNodePath = Hocon::Impl::ConfigNodePath
  ConfigValueType = Hocon::ConfigValueType
  ConfigBadPathError = Hocon::ConfigError::ConfigBadPathError



  class Element
    def initialize(initial, can_be_empty)
      @can_be_empty = can_be_empty
      @sb = StringIO.new(initial)
    end

    attr_accessor :can_be_empty, :sb

    def to_string
      "Element(#{@sb.string},#{@can_be_empty})"
    end
  end

  def self.api_origin
    SimpleConfigOrigin.new_simple("path parameter")
  end

  def self.parse_path_node(path, flavor = ConfigSyntax::CONF)
    reader = StringIO.new(path)

    begin
      tokens = Tokenizer.tokenize(api_origin, reader,
                                  flavor)
      tokens.next # drop START
      parse_path_node_expression(tokens, api_origin, path, flavor)
    ensure
      reader.close
    end
  end

  def self.parse_path(path)
    speculated = speculative_fast_parse_path(path)
    if not speculated.nil?
      return speculated
    end

    reader = StringIO.new(path)

    begin
      tokens = Tokenizer.tokenize(api_origin, reader, ConfigSyntax::CONF)
      tokens.next # drop START
      return parse_path_expression(tokens, api_origin, path)
    ensure
      reader.close
    end
  end

  def self.parse_path_node_expression(expression, origin, original_text = nil,
                                      flavor = ConfigSyntax::CONF)
    path_tokens = []
    path = parse_path_expression(expression, origin, original_text, path_tokens, flavor)
    ConfigNodePath.new(path, path_tokens);
  end

  def self.parse_path_expression(expression, origin, original_text = nil,
                                  path_tokens = nil, flavor = ConfigSyntax::CONF)
    # each builder in "buf" is an element in the path
    buf = []
    buf.push(Element.new("", false))

    if !expression.has_next?
      raise ConfigBadPathError.new(
                origin,
                original_text,
                "Expecting a field name or path here, but got nothing")
    end

    while expression.has_next?
      t = expression.next

      if ! path_tokens.nil?
        path_tokens << t
      end

      # Ignore all IgnoredWhitespace tokens
      next if Tokens.ignored_whitespace?(t)

      if Tokens.value_with_type?(t, ConfigValueType::STRING)
        v = Tokens.value(t)
        # this is a quoted string; so any periods
        # in here don't count as path separators
        s = v.transform_to_string
        add_path_text(buf, true, s)
      elsif t == Tokens::EOF
        # ignore this; when parsing a file, it should not happen
        # since we're parsing a token list rather than the main
        # token iterator, and when parsing a path expression from the
        # API, it's expected to have an EOF.
      else
        # any periods outside of a quoted string count as
        # separators
        text = nil
        if Tokens.value?(t)
          # appending a number here may add
          # a period, but we _do_ count those as path
          # separators, because we basically want
          # "foo 3.0bar" to parse as a string even
          # though there's a number in it. The fact that
          # we tokenize non-string values is largely an
          # implementation detail.
          v = Tokens.value(t)

          # We need to split the tokens on a . so that we can get sub-paths but still preserve
          # the original path text when doing an insertion
          if ! path_tokens.nil?
            path_tokens.delete_at(path_tokens.size - 1)
            path_tokens.concat(split_token_on_period(t, flavor))
          end
          text = v.transform_to_string
        elsif Tokens.unquoted_text?(t)
          # We need to split the tokens on a . so that we can get sub-paths but still preserve
          # the original path text when doing an insertion on ConfigNodeObjects
          if ! path_tokens.nil?
            path_tokens.delete_at(path_tokens.size - 1)
            path_tokens.concat(split_token_on_period(t, flavor))
          end
          text = Tokens.unquoted_text(t)
        else
          raise ConfigBadPathError.new(
                    origin,
                    original_text,
                    "Token not allowed in path expression: #{t}" +
                        " (you can double-quote this token if you really want it here)")
        end

        add_path_text(buf, false, text)
      end
    end

    pb = Hocon::Impl::PathBuilder.new
    buf.each do |e|
      if (e.sb.length == 0) && !e.can_be_empty
        raise Hocon::ConfigError::ConfigBadPathError.new(
                  origin,
                  original_text,
                  "path has a leading, trailing, or two adjacent period '.' (use quoted \"\" empty string if you want an empty element)")
      else
        pb.append_key(e.sb.string)
      end
    end

    pb.result
  end

  def self.split_token_on_period(t, flavor)
    token_text = t.token_text
    if token_text == "."
      return [t]
    end
    split_token = token_text.split('.')
    split_tokens = []
    split_token.each do |s|
      if flavor == ConfigSyntax::CONF
        split_tokens << Tokens.new_unquoted_text(t.origin, s)
      else
        split_tokens << Tokens.new_string(t.origin, s, "\"#{s}\"")
      end
      split_tokens << Tokens.new_unquoted_text(t.origin, ".")
    end
    if token_text[-1] != "."
      split_tokens.delete_at(split_tokens.size - 1)
    end
    split_tokens
  end

  def self.add_path_text(buf, was_quoted, new_text)
    i = if was_quoted
          -1
        else
          new_text.index('.') || -1
        end
    current = buf.last
    if i < 0
      # add to current path element
      current.sb << new_text
      # any empty quoted string means this element can
      # now be empty.
      if was_quoted && (current.sb.length == 0)
        current.can_be_empty = true
      end
    else
      # "buf" plus up to the period is an element
      current.sb << new_text[0, i]
      # then start a new element
      buf.push(Element.new("", false))
      # recurse to consume remainder of new_text
      add_path_text(buf, false, new_text[i + 1, new_text.length - 1])
    end
  end

  # the idea is to see if the string has any chars or features
  # that might require the full parser to deal with.
  def self.looks_unsafe_for_fast_parser(s)
    last_was_dot = true # // start of path is also a "dot"
    len = s.length
    if s.empty?
      return true
    end
    if s[0] == "."
      return true
    end
    if s[len - 1] == "."
      return true
    end

    (0..len).each do |i|
      c = s[i]
      if c =~ /^\w$/
        last_was_dot = false
        next
      elsif c == '.'
        if last_was_dot
          return true # ".." means we need to throw an error
        end
        last_was_dot = true
      elsif c == '-'
        if last_was_dot
          return true
        end
        next
      else
        return true
      end
    end

    if last_was_dot
      return true
    end

    false
  end

  def self.fast_path_build(tail, s, path_end)
    # rindex takes last index it should look at, end - 1 not end
    split_at = s.rindex(".", path_end - 1)
    tokens = []
    tokens << Tokens.new_unquoted_text(nil, s)
    # this works even if split_at is -1; then we start the substring at 0
    with_one_more_element = Path.new(s[split_at + 1..path_end], tail)
    if split_at < 0
      with_one_more_element
    else
      fast_path_build(with_one_more_element, s, split_at)
    end
  end

  # do something much faster than the full parser if
  # we just have something like "foo" or "foo.bar"
  def self.speculative_fast_parse_path(path)
    s = Hocon::Impl::ConfigImplUtil.unicode_trim(path)
    if looks_unsafe_for_fast_parser(s)
      return nil
    end

    fast_path_build(nil, s, s.length)
  end

end
