# encoding: utf-8

require 'stringio'
require 'hocon/impl'
require 'hocon/config_error'
require 'hocon/impl/tokens'
require 'hocon/impl/config_node_single_token'
require 'hocon/impl/config_node_comment'
require 'hocon/impl/abstract_config_node_value'
require 'hocon/impl/config_node_concatenation'
require 'hocon/impl/config_include_kind'
require 'hocon/impl/config_node_object'
require 'hocon/impl/config_node_array'
require 'hocon/impl/config_node_root'

class Hocon::Impl::ConfigDocumentParser

  ConfigSyntax = Hocon::ConfigSyntax
  ConfigParseError = Hocon::ConfigError::ConfigParseError
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  ConfigValueType = Hocon::ConfigValueType
  Tokens = Hocon::Impl::Tokens
  PathParser = Hocon::Impl::PathParser
  ArrayIterator = Hocon::Impl::ArrayIterator
  ConfigImplUtil = Hocon::Impl::ConfigImplUtil
  ConfigIncludeKind = Hocon::Impl::ConfigIncludeKind
  ConfigNodeSingleToken = Hocon::Impl::ConfigNodeSingleToken
  ConfigNodeSimpleValue = Hocon::Impl::ConfigNodeSimpleValue
  ConfigNodeInclude = Hocon::Impl::ConfigNodeInclude
  ConfigNodeField = Hocon::Impl::ConfigNodeField
  ConfigNodeObject = Hocon::Impl::ConfigNodeObject
  ConfigNodeArray = Hocon::Impl::ConfigNodeArray
  ConfigNodeRoot = Hocon::Impl::ConfigNodeRoot

  def self.parse(tokens, origin, options)
    syntax = options.syntax.nil? ? ConfigSyntax::CONF : options.syntax
    context = Hocon::Impl::ConfigDocumentParser::ParseContext.new(syntax, origin, tokens)
    context.parse
  end

  def self.parse_value(tokens, origin, options)
    syntax = options.syntax.nil? ? ConfigSyntax::CONF : options.syntax
    context = Hocon::Impl::ConfigDocumentParser::ParseContext.new(syntax, origin, tokens)
    context.parse_single_value
  end

  class ParseContext
    def initialize(flavor, origin, tokens)
      @line_number = 1
      @buffer = []
      @tokens = tokens
      @flavor = flavor
      @equals_count = 0
      @base_origin = origin
    end

    def pop_token
      if @buffer.empty?
        return @tokens.next
      end
      @buffer.pop
    end

    def next_token
      t = pop_token
      if @flavor.equal?(ConfigSyntax::JSON)
        if Tokens.unquoted_text?(t) && !unquoted_whitespace?(t)
          raise parse_error("Token not allowed in valid JSON: '#{Tokens.unquoted_text(t)}'")
        elsif Tokens.substitution?(t)
          raise parse_error("Substitutions (${} syntax) not allowed in JSON")
        end
      end
      t
    end

    def next_token_collecting_whitespace(nodes)
      while true
        t = next_token
        if Tokens.ignored_whitespace?(t) || Tokens.newline?(t) || unquoted_whitespace?(t)
          nodes.push(ConfigNodeSingleToken.new(t))
          if Tokens.newline?(t)
            @line_number = t.line_number + 1
          end
        elsif Tokens.comment?(t)
          nodes.push(Hocon::Impl::ConfigNodeComment.new(t))
        else
          new_number = t.line_number
          if new_number >= 0
            @line_number = new_number
          end
          return t
        end
      end
    end

    def put_back(token)
      @buffer.push(token)
    end

    # In arrays and objects, comma can be omitted
    # as long as there's at least one newline instead.
    # this skips any newlines in front of a comma,
    # skips the comma, and returns true if it found
    # either a newline or a comma. The iterator
    # is left just after the comma or the newline.
    def check_element_separator(nodes)
      if @flavor.equal?(ConfigSyntax::JSON)
        t = next_token_collecting_whitespace(nodes)
        if t.equal?(Tokens::COMMA)
          nodes.push(ConfigNodeSingleToken.new(t))
          return true
        else
          put_back(t)
          return false
        end
      else
        saw_separator_or_new_line = false
        t = next_token
        while true
          if Tokens.ignored_whitespace?(t) || unquoted_whitespace?(t)
            nodes.push(ConfigNodeSingleToken.new(t))
          elsif Tokens.comment?(t)
            nodes.push(Hocon::Impl::ConfigNodeComment.new(t))
          elsif Tokens.newline?(t)
            saw_separator_or_new_line = true
            @line_number += 1
            nodes.push(ConfigNodeSingleToken.new(t))
            # we want to continue to also eat
            # a comma if there is one.
          elsif t.equal?(Tokens::COMMA)
            nodes.push(ConfigNodeSingleToken.new(t))
            return true
          else
            # non-newline-or-comma
            put_back(t)
            return saw_separator_or_new_line
          end
          t = next_token
        end
      end
    end

    # parse a concatenation. If there is no concatenation, return the next value
    def consolidate_values(nodes)
      # this trick is not done in JSON
      if @flavor.equal?(ConfigSyntax::JSON)
        return nil
      end

      # create only if we have value tokens
      values = []
      value_count = 0

      # ignore a newline up front
      t = next_token_collecting_whitespace(nodes)
      while true
        v = nil
        if Tokens.ignored_whitespace?(t)
          values.push(ConfigNodeSingleToken.new(t))
          t = next_token
          next
        elsif Tokens.value?(t) || Tokens.unquoted_text?(t) || Tokens.substitution?(t) || t == Tokens::OPEN_CURLY || t == Tokens::OPEN_SQUARE
          # there may be newlines _within_ the objects and arrays
          v = parse_value(t)
          value_count += 1
        else
          break
        end

        if v.nil?
          raise ConfigBugOrBrokenError, "no value"
        end

        values.push(v)
        t = next_token # but don't consolidate across a newline
      end

      put_back(t)

      # No concatenation was seen, but a single value may have been parsed, so return it, and put back
      # all succeeding tokens
      if value_count < 2
        value = nil
        values.each do |node|
          if node.is_a?(Hocon::Impl::AbstractConfigNodeValue)
            value = node
          elsif value.nil?
            nodes.add(node)
          else
            put_back(node.tokens[0])
          end
        end
        return value
      end

      # Put back any trailing whitespace, as the parent object is responsible for tracking
      # any leading/trailing whitespace
      for i in (0..values.size - 1).reverse_each
        if values[i].is_a?(ConfigNodeSingleToken)
          put_back(values[i].token)
          values.delete_at(i)
        else
          break
        end
      end
      Hocon::Impl::ConfigNodeConcatenation.new(values)
    end

    def parse_error(message, cause = nil)
      ConfigParseError.new(@base_origin.with_line_number(@line_number), message, cause)
    end

    def add_quote_suggestion(bad_token, message, last_path = nil, inside_equals = nil)
      if inside_equals.nil?
        inside_equals = @equals_count > 0
      end

      previous_field_name = last_path != nil ? last_path.render : nil

      if bad_token == Tokens::EOF.to_s
        # EOF requires special handling for the error to make sense.
        if previous_field_name != nil
          part = "#{message} (if you intended '#{previous_field_name}'" +
              "' to be part of a value, instead of a key, " +
              "try adding double quotes around the whole value"
        else
          return message
        end
      else
        if previous_field_name != nil
          part = "#{message} (if you intended #{bad_token}" +
              " to be part of the value for '#{previous_field_name}', " +
              "try enclosing the value in double quotes"
        else
          part = "#{message} (if you intended #{bad_token}" +
              " to be part of a key or string value, " +
              "try enclosing the key or value in double quotes"
        end
      end

      # Don't have a special case to throw a message about changing the file to .properties, since
      # we don't support that format
      part
    end

    def parse_value(t)
      v = nil
      starting_equals_count = @equals_count

      if Tokens.value?(t) || Tokens.unquoted_text?(t) || Tokens.substitution?(t)
        v = Hocon::Impl::ConfigNodeSimpleValue.new(t)
      elsif t.equal?(Tokens::OPEN_CURLY)
        v = parse_object(true)
      elsif t.equal?(Tokens::OPEN_SQUARE)
        v = parse_array
      else
        raise parse_error(add_quote_suggestion(t.to_s, "Expecting a value but got wrong token: #{t}"))
      end

      if @equals_count != starting_equals_count
        raise ConfigBugOrBrokenError, "Bug in config parser: unbalanced equals count"
      end

      v
    end

    def parse_key(token)
      if @flavor.equal?(ConfigSyntax::JSON)
        if Tokens.value_with_type?(token, ConfigValueType::STRING)
          return PathParser.parse_path_node_expression(Hocon::Impl::ArrayIterator.new([token]), nil)
        else
          raise ConfigParseError, "Expecting close brace } or a field name here, got #{token}"
        end
      else
        expression = []
        t = token
        while Tokens.value?(t) || Tokens.unquoted_text?(t)
          expression.push(t)
          t = next_token # note: don't cross a newline
        end

        if expression.empty?
          raise parse_error("expecting a close brace or a field name here, got #{t}")
        end

        put_back(t) # put back the token we ended with
        PathParser.parse_path_node_expression(ArrayIterator.new(expression), nil)
      end
    end

    def include_keyword?(t)
      Tokens.unquoted_text?(t) && Tokens.unquoted_text(t) == "include"
    end

    def unquoted_whitespace?(t)
      unless Tokens.unquoted_text?(t)
        return false
      end

      s = Tokens.unquoted_text(t)

      s.each_char do |c|
        unless ConfigImplUtil.whitespace?(c)
          return false
        end
      end
      true
    end

    def key_value_separator?(t)
      if @flavor.equal?(ConfigSyntax::JSON)
        t.equal?(Tokens::COLON)
      else
        t.equal?(Tokens::COLON) || t.equal?(Tokens::EQUALS) || t.equal?(Tokens::PLUS_EQUALS)
      end
    end

    def parse_include(children)
      t = next_token_collecting_whitespace(children)

      # we either have a quoted string or the "file()" syntax
      if Tokens.unquoted_text?(t)
        # get foo(
        kind_text = Tokens.unquoted_text(t)

        if kind_text == "url("
          kind = ConfigIncludeKind::URL
        elsif kind_text == "file("
          kind = ConfigIncludeKind::FILE
        elsif kind_text == "classpath("
          kind = ConfigIncludeKind::CLASSPATH
        else
          raise parse_error("expecting include parameter to be quoted filename, file(), classpath(), or url(). No spaces are allowed before the open paren. Not expecting: #{t}")
        end

        children.push(ConfigNodeSingleToken.new(t))

        # skip space inside parens
        t = next_token_collecting_whitespace(children)

        # quoted string
        unless Tokens.value_with_type?(t, ConfigValueType::STRING)
          raise parse_error("expecting a quoted string inside file(), classpath(), or url(), rather than: #{t}")
        end
        children.push(ConfigNodeSimpleValue.new(t))
        # skip space after string, inside parens
        t = next_token_collecting_whitespace(children)

        if Tokens.unquoted_text?(t) && Tokens.unquoted_text(t) == ")"
          # OK, close paren
        else
          raise parse_error("expecting a close parentheses ')' here, not: #{t}")
        end
        ConfigNodeInclude.new(children, kind)
      elsif Tokens.value_with_type?(t, ConfigValueType::STRING)
        children.push(ConfigNodeSimpleValue.new(t))
        ConfigNodeInclude.new(children, ConfigIncludeKind::HEURISTIC)
      else
        raise parse_error("include keyword is not followed by a quoted string, but by: #{t}")
      end
    end

    def parse_object(had_open_curly)
      # invoked just after the OPEN_CURLY (or START, if !hadOpenCurly)
      after_comma = false
      last_path = nil
      last_inside_equals = false
      object_nodes = []
      keys = Hash.new
      if had_open_curly
        object_nodes.push(ConfigNodeSingleToken.new(Tokens::OPEN_CURLY))
      end

      while true
        t = next_token_collecting_whitespace(object_nodes)
        if t.equal?(Tokens::CLOSE_CURLY)
          if @flavor.equal?(ConfigSyntax::JSON) && after_comma
            raise parse_error(add_quote_suggestion(t.to_s,
                                                   "expecting a field name after a comma, got a close brace } instead"))
          elsif !had_open_curly
            raise parse_error(add_quote_suggestion(t.to_s,
                                                   "unbalanced close brace '}' with no open brace"))
          end
          object_nodes.push(ConfigNodeSingleToken.new(Tokens::CLOSE_CURLY))
          break
        elsif t.equal?(Tokens::EOF) && !had_open_curly
          put_back(t)
          break
        elsif !@flavor.equal?(ConfigSyntax::JSON) && include_keyword?(t)
          include_nodes = []
          include_nodes.push(ConfigNodeSingleToken.new(t))
          object_nodes.push(parse_include(include_nodes))
          after_comma = false
        else
          key_value_nodes = []
          key_token = t
          path = parse_key(key_token)
          key_value_nodes.push(path)
          after_key = next_token_collecting_whitespace(key_value_nodes)
          inside_equals = false

          if @flavor.equal?(ConfigSyntax::CONF) && after_key.equal?(Tokens::OPEN_CURLY)
            # can omit the ':' or '=' before an object value
            next_value = parse_value(after_key)
          else
            unless key_value_separator?(after_key)
              raise parse_error(add_quote_suggestion(after_key.to_s,
                                                     "Key '#{path.render()}' may not be followed by token: #{after_key}"))
            end

            key_value_nodes.push(ConfigNodeSingleToken.new(after_key))

            if after_key.equal?(Tokens::EQUALS)
              inside_equals = true
              @equals_count += 1
            end

            next_value = consolidate_values(key_value_nodes)
            if next_value.nil?
              next_value = parse_value(next_token_collecting_whitespace(key_value_nodes))
            end
          end

          key_value_nodes.push(next_value)
          if inside_equals
            @equals_count -= 1
          end
          last_inside_equals = inside_equals

          key = path.value.first
          remaining = path.value.remainder

          if remaining.nil?
            existing = keys[key]
            unless existing.nil?
              # In strict JSON, dups should be an error; while in
              # our custom config language, they should be merged
              # if the value is an object (or substitution that
              # could become an object).

              if @flavor.equal?(ConfigSyntax::JSON)
                raise parse_error("JSON does not allow duplicate fields: '#{key}' was already seen")
              end
            end
            keys[key] = true
          else
            if @flavor.equal?(ConfigSyntax::JSON)
              raise ConfigBugOrBrokenError, "somehow got multi-element path in JSON mode"
            end
            keys[key] = true
          end

          after_comma = false
          object_nodes.push(ConfigNodeField.new(key_value_nodes))
        end

        if check_element_separator(object_nodes)
          # continue looping
          after_comma = true
        else
          t = next_token_collecting_whitespace(object_nodes)
          if t.equal?(Tokens::CLOSE_CURLY)
            unless had_open_curly
              raise parse_error(add_quote_suggestion(t.to_s,
                                                     "unbalanced close brace '}' with no open brace",
                                                     last_path,
                                                     last_inside_equals,))
            end
            object_nodes.push(ConfigNodeSingleToken.new(t))
            break
          elsif had_open_curly
            raise parse_error(add_quote_suggestion(t.to_s,
                                                   "Expecting close brace } or a comma, got #{t}",
                                                   last_path,
                                                   last_inside_equals,))
          else
            if t.equal?(Tokens::EOF)
              put_back(t)
              break
            else
              raise parse_error(add_quote_suggestion(t.to_s,
                                                     "Expecting close brace } or a comma, got #{t}",
                                                     last_path,
                                                     last_inside_equals,))
            end
          end
        end
      end

      ConfigNodeObject.new(object_nodes)
    end

    def parse_array
      children = []
      children.push(ConfigNodeSingleToken.new(Tokens::OPEN_SQUARE))
      # invoked just after the OPEN_SQUARE
      t = nil

      next_value = consolidate_values(children)
      unless next_value.nil?
        children.push(next_value)
      else
        t = next_token_collecting_whitespace(children)

        # special-case the first element
        if t.equal?(Tokens::CLOSE_SQUARE)
          children.push(ConfigNodeSingleToken.new(t))
          return ConfigNodeArray.new(children)
        elsif Tokens.value?(t) || t.equal?(Tokens::OPEN_CURLY) ||
                t.equal?(Tokens::OPEN_SQUARE) || Tokens.unquoted_text?(t) ||
                Tokens.substitution?(t)
          next_value = parse_value(t)
          children.push(next_value)
        else
          raise parse_error("List should have ] or a first element after the open [, instead had token: #{t}" +
                " (if you want #{t} to be part of a string value, then double-quote it)")
        end
      end

      # now remaining elements
      while true
        # just after a value
        if check_element_separator(children)
          # comma (or newline equivalent) consumed
        else
          t = next_token_collecting_whitespace(children)
          if t.equal?(Tokens::CLOSE_SQUARE)
            children.push(ConfigNodeSingleToken.new(t))
            return ConfigNodeArray.new(children)
          else
            raise parse_error("List should have ended with ] or had a comma, instead had token: #{t}" +
                  " (if you want #{t} to be part of a string value, then double-quote it)")
          end
        end

        # now just after a comma
        next_value = consolidate_values(children)
        unless next_value.nil?
          children.push(next_value)
        else
          t = next_token_collecting_whitespace(children)
          if Tokens.value?(t) || t.equal?(Tokens::OPEN_CURLY) ||
              t.equal?(Tokens::OPEN_SQUARE) || Tokens.unquoted_text?(t) ||
              Tokens.substitution?(t)
            next_value = parse_value(t)
            children.push(next_value)
          elsif !@flavor.equal?(ConfigSyntax::JSON) && t.equal?(Tokens::CLOSE_SQUARE)
            # we allow one trailing comma
            put_back(t)
          else
            raise parse_error("List should have had new element after a comma, instead had token: #{t}" +
                  " (if you want the comma or #{t} to be part of a string value, then double-quote it)")
          end
        end
      end
    end

    def parse
      children = []
      t = next_token
      if t.equal?(Tokens::START)
        # OK
      else
        raise ConfigBugOrBrokenException, "token stream did not begin with START, had #{t}"
      end

      t = next_token_collecting_whitespace(children)
      result = nil
      missing_curly = false
      if t.equal?(Tokens::OPEN_CURLY) || t.equal?(Tokens::OPEN_SQUARE)
        result = parse_value(t)
      else
        if @flavor.equal?(ConfigSyntax::JSON)
          if t.equal?(Tokens::EOF)
            raise parse_error("Empty document")
          else
            raise parse_error("Document must have an object or array at root, unexpected token: #{t}")
          end
        else
          # the root object can omit the surrounding braces.
          # this token should be the first field's key, or part
          # of it, so put it back.
          put_back(t)
          missing_curly = true
          result = parse_object(false)
        end
      end

      # Need to pull the children out of the resulting node so we can keep leading
      # and trailing whitespace if this was a no-brace object. Otherwise, we need to add
      # the result into the list of children.
      if result.is_a?(ConfigNodeObject) && missing_curly
        children += result.children
      else
        children.push(result)
      end
      t = next_token_collecting_whitespace(children)
      if t.equal?(Tokens::EOF)
        if missing_curly
          # If there were no braces, the entire document should be treated as a single object
          ConfigNodeRoot.new([ConfigNodeObject.new(children)], @base_origin)
        else
          ConfigNodeRoot.new(children, @base_origin)
        end
      else
        raise parse_error("Document has trailing tokens after first object or array: #{t}")
      end
    end

    # Parse a given input stream into a single value node. Used when doing a replace inside a ConfigDocument.
    def parse_single_value
      t = next_token
      if t.equal?(Tokens::START)
        # OK
      else
        raise ConfigBugOrBrokenError, "token stream did not begin with START, had #{t}"
      end

      t = next_token
      if Tokens.ignored_whitespace?(t) || Tokens.newline?(t) || unquoted_whitespace?(t) || Tokens.comment?(t)
        raise parse_error("The value from setValue cannot have leading or trailing newlines, whitespace, or comments")
      end
      if t.equal?(Tokens::EOF)
        raise parse_error("Empty value")
      end
      if @flavor.equal?(ConfigSyntax::JSON)
        node = parse_value(t)
        t = next_token
        if t.equal?(Tokens::EOF)
          return node
        else
          raise parse_error("Parsing JSON and the value set in setValue was either a concatenation or had trailing whitespace, newlines, or comments")
        end
      else
        put_back(t)
        nodes = []
        node = consolidate_values(nodes)
        t = next_token
        if t.equal?(Tokens::EOF)
          node
        else
          raise parse_error("The value from setValue cannot have leading or trailing newlines, whitespace, or comments")
        end
      end
    end
  end
end