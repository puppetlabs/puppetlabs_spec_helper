# encoding: utf-8

require 'stringio'
require 'hocon/impl'
require 'hocon/impl/path_builder'
require 'hocon/config_syntax'
require 'hocon/impl/config_string'
require 'hocon/impl/config_concatenation'
require 'hocon/config_error'
require 'hocon/impl/simple_config_list'
require 'hocon/impl/simple_config_object'
require 'hocon/impl/path'
require 'hocon/impl/url'
require 'hocon/impl/config_reference'
require 'hocon/impl/substitution_expression'
require 'hocon/impl/config_node_simple_value'
require 'hocon/impl/config_node_object'
require 'hocon/impl/config_node_array'
require 'hocon/impl/config_node_concatenation'
require 'hocon/impl/config_include_kind'

class Hocon::Impl::ConfigParser

  ConfigSyntax = Hocon::ConfigSyntax
  ConfigConcatenation = Hocon::Impl::ConfigConcatenation
  ConfigReference = Hocon::Impl::ConfigReference
  ConfigParseError = Hocon::ConfigError::ConfigParseError
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
  SimpleConfigObject = Hocon::Impl::SimpleConfigObject
  SimpleConfigList = Hocon::Impl::SimpleConfigList
  Path = Hocon::Impl::Path
  ConfigIncludeKind = Hocon::Impl::ConfigIncludeKind
  ConfigNodeInclude = Hocon::Impl::ConfigNodeInclude
  ConfigNodeComment = Hocon::Impl::ConfigNodeComment
  ConfigNodeSingleToken = Hocon::Impl::ConfigNodeSingleToken
  Tokens = Hocon::Impl::Tokens

  def self.parse(document, origin, options, include_context)
    context = Hocon::Impl::ConfigParser::ParseContext.new(
        options.syntax, origin, document,
        Hocon::Impl::SimpleIncluder.make_full(options.includer),
        include_context)
    context.parse
  end

  class ParseContext
    def initialize(flavor, origin, document, includer, include_context)
      @line_number = 1
      @document = document
      @flavor = flavor
      @base_origin = origin
      @includer = includer
      @include_context = include_context
      @path_stack = []
      @array_count = 0
    end

    # merge a bunch of adjacent values into one
    # value; change unquoted text into a string
    # value.
    def parse_concatenation(n)
      # this trick is not done in JSON
      if @flavor.equal?(ConfigSyntax::JSON)
        raise ConfigBugOrBrokenError, "Found a concatenation node in JSON"
      end

      values = []

      n.children.each do |node|
        if node.is_a?(Hocon::Impl::AbstractConfigNodeValue)
          v = parse_value(node, nil)
          values.push(v)
        end
      end

      ConfigConcatenation.concatenate(values)
    end

    def line_origin
      @base_origin.with_line_number(@line_number)
    end

    def parse_error(message, cause = nil)
      ConfigParseError.new(line_origin, message, cause)
    end

    def full_current_path
      # pathStack has top of stack at front
      if @path_stack.empty?
        raise ConfigBugOrBrokenError, "Bug in parser; tried to get current path when at root"
      else
        Path.from_path_list(@path_stack.reverse)
      end
    end

    def parse_value(n, comments)
      starting_array_count = @array_count

      if n.is_a?(Hocon::Impl::ConfigNodeSimpleValue)
        v = n.value
      elsif n.is_a?(Hocon::Impl::ConfigNodeObject)
        v = parse_object(n)
      elsif n.is_a?(Hocon::Impl::ConfigNodeArray)
        v = parse_array(n)
      elsif n.is_a?(Hocon::Impl::ConfigNodeConcatenation)
        v = parse_concatenation(n)
      else
        raise parse_error("Expecting a value but got wrong node type: #{n.class}")
      end

      unless comments.nil? || comments.empty?
        v = v.with_origin(v.origin.prepend_comments(comments.clone))
        comments.clear
      end

      unless @array_count == starting_array_count
        raise ConfigBugOrBrokenError, "Bug in config parser: unbalanced array count"
      end

      v
    end

    def create_value_under_path(path, value)
      # for path foo.bar, we are creating
      # { "foo" : { "bar" : value } }
      keys = []

      key = path.first
      remaining = path.remainder
      until key.nil?
        keys.push(key)
        if remaining.nil?
          break
        else
          key = remaining.first
          remaining = remaining.remainder
        end
      end

      # the setComments(null) is to ensure comments are only
      # on the exact leaf node they apply to.
      # a comment before "foo.bar" applies to the full setting
      # "foo.bar" not also to "foo"
      keys = keys.reverse
      # this is just a ruby means for doing first/rest
      deepest, *rest = *keys
      o = SimpleConfigObject.new(value.origin.with_comments(nil),
                                 {deepest => value})
      while !rest.empty?
        deepest, *rest = *rest
        o = SimpleConfigObject.new(value.origin.with_comments(nil),
                                   {deepest => o})
      end

      o
    end

    def parse_include(values, n)
      case n.kind
        when ConfigIncludeKind::URL
          url = nil
          begin
            url = Hocon::Impl::Url.new(n.name)
          rescue Hocon::Impl::Url::MalformedUrlError => e
            raise parse_error("include url() specifies an invalid URL: #{n.name}", e)
          end
          obj = @includer.include_url(@include_context, url)
        when ConfigIncludeKind::FILE
          obj = @includer.include_file(@include_context, n.name)
        when ConfigIncludeKind::CLASSPATH
          obj = @includer.include_resources(@include_context, n.name)
        when ConfigIncludeKind::HEURISTIC
          obj = @includer.include(@include_context, n.name)
        else
          raise ConfigBugOrBrokenError, "should not be reached"
      end

      # we really should make this work, but for now throwing an
      # exception is better than producing an incorrect result.
      # See https://github.com/typesafehub/config/issues/160
      if @array_count > 0 && (obj.resolve_status != Hocon::Impl::ResolveStatus::RESOLVED)
        raise parse_error("Due to current limitations of the config parser, when an include statement is nested inside a list value, " +
                              "${} substitutions inside the included file cannot be resolved correctly. Either move the include outside of the list value or " +
                              "remove the ${} statements from the included file.")
      end

      if !(@path_stack.empty?)
        prefix = full_current_path
        obj = obj.relativized(prefix)
      end

      obj.key_set.each do |key|
        v = obj.get(key)
        existing = values[key]
        if !(existing.nil?)
          values[key] = v.with_fallback(existing)
        else
          values[key] = v
        end
      end
    end

    def parse_object(n)
      values = Hash.new
      object_origin = line_origin
      last_was_new_line = false

      nodes = n.children.clone
      comments = []
      i = 0
      while i < nodes.size
        node = nodes[i]
        if node.is_a?(ConfigNodeComment)
          last_was_new_line = false
          comments.push(node.comment_text)
        elsif node.is_a?(ConfigNodeSingleToken) && Tokens.newline?(node.token)
          @line_number += 1
          if last_was_new_line
            # Drop all comments if there was a blank line and start a new comment block
            comments.clear
          end
          last_was_new_line = true
        elsif !@flavor.equal?(ConfigSyntax::JSON) && node.is_a?(ConfigNodeInclude)
          parse_include(values, node)
          last_was_new_line = false
        elsif node.is_a?(Hocon::Impl::ConfigNodeField)
          last_was_new_line = false
          path = node.path.value
          comments += node.comments

          # path must be on-stack while we parse the value
          # Note that, in upstream, pathStack is a LinkedList, so use unshift instead of push
          @path_stack.unshift(path)
          if node.separator.equal?(Tokens::PLUS_EQUALS)
            # we really should make this work, but for now throwing
            # an exception is better than producing an incorrect
            # result. See
            # https://github.com/typesafehub/config/issues/160
            if @array_count > 0
              raise parse_error("Due to current limitations of the config parser, += does not work nested inside a list. " +
                                    "+= expands to a ${} substitution and the path in ${} cannot currently refer to list elements. " +
                                    "You might be able to move the += outside of the list and then refer to it from inside the list with ${}.")
            end

            # because we will put it in an array after the fact so
            # we want this to be incremented during the parseValue
            # below in order to throw the above exception.
            @array_count += 1
          end

          value_node = node.value

          # comments from the key token go to the value token
          new_value = parse_value(value_node, comments)

          if node.separator.equal?(Tokens::PLUS_EQUALS)
            @array_count -= 1

            concat = []
            previous_ref = ConfigReference.new(new_value.origin,
                                               Hocon::Impl::SubstitutionExpression.new(full_current_path, true))
            list = SimpleConfigList.new(new_value.origin, [new_value])
            concat << previous_ref
            concat << list
            new_value = ConfigConcatenation.concatenate(concat)
          end

          # Grab any trailing comments on the same line
          if i < nodes.size - 1
            i += 1
            while i < nodes.size
              if nodes[i].is_a?(ConfigNodeComment)
                comment = nodes[i]
                new_value = new_value.with_origin(new_value.origin.append_comments([comment.comment_text]))
                break
              elsif nodes[i].is_a?(ConfigNodeSingleToken)
                curr = nodes[i]
                if curr.token.equal?(Tokens::COMMA) || Tokens.ignored_whitespace?(curr.token)
                  # keep searching, as there could still be a comment
                else
                  i -= 1
                  break
                end
              else
                i -= 1
                break
              end
              i += 1
            end
          end

          @path_stack.shift

          key = path.first
          remaining = path.remainder

          if remaining.nil?
            existing = values[key]
            unless existing.nil?
              # In strict JSON, dups should be an error; while in
              # our custom config language, they should be merged
              # if the value is an object (or substitution that
              # could become an object).

              if @flavor.equal?(ConfigSyntax::JSON)
                raise parse_error("JSON does not allow duplicate fields: '#{key}'" +
                                      " was already seen at #{existing.origin().description()}")
              else
                new_value = new_value.with_fallback(existing)
              end
            end
            values[key] = new_value
          else
            if @flavor == ConfigSyntax::JSON
              raise Hocon::ConfigError::ConfigBugOrBrokenError, "somehow got multi-element path in JSON mode"
            end

            obj = create_value_under_path(remaining, new_value)
            existing = values[key]
            if !existing.nil?
              obj = obj.with_fallback(existing)
            end
            values[key] = obj
          end
        end
        i += 1
      end

      SimpleConfigObject.new(object_origin, values)
    end

    def parse_array(n)
      @array_count += 1

      array_origin = line_origin
      values = []

      last_was_new_line = false
      comments = []

      v = nil

      n.children.each do |node|
        if node.is_a?(ConfigNodeComment)
          comments << node.comment_text
          last_was_new_line = false
        elsif node.is_a?(ConfigNodeSingleToken) && Tokens.newline?(node.token)
          @line_number += 1
          if last_was_new_line && v.nil?
            comments.clear
          elsif !v.nil?
            values << v.with_origin(v.origin.append_comments(comments.clone))
            comments.clear
            v = nil
          end
          last_was_new_line = true
        elsif node.is_a?(Hocon::Impl::AbstractConfigNodeValue)
          last_was_new_line = false
          unless v.nil?
            values << v.with_origin(v.origin.append_comments(comments.clone))
            comments.clear
          end
          v = parse_value(node, comments)
        end
      end
      # There shouldn't be any comments at this point, but add them just in case
      unless v.nil?
        values << v.with_origin(v.origin.append_comments(comments.clone))
      end
      @array_count -= 1
      SimpleConfigList.new(array_origin, values)
    end

    def parse
      result = nil
      comments = []
      last_was_new_line = false
      @document.children.each do |node|
        if node.is_a?(ConfigNodeComment)
          comments << node.comment_text
          last_was_new_line = false
        elsif node.is_a?(ConfigNodeSingleToken)
          t = node.token
          if Tokens.newline?(t)
            @line_number += 1
            if last_was_new_line && result.nil?
              comments.clear
            elsif !result.nil?
              result = result.with_origin(result.origin.append_comments(comments.clone))
              comments.clear
              break
            end
            last_was_new_line = true
          end
        elsif node.is_a?(Hocon::Impl::ConfigNodeComplexValue)
          result = parse_value(node, comments)
          last_was_new_line = false
        end
      end
      result
    end
  end
end
