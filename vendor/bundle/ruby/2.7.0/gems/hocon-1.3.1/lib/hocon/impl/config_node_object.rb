# encoding: utf-8

require 'hocon/config_syntax'
require 'hocon/impl'
require 'hocon/impl/config_node_complex_value'
require 'hocon/impl/config_node_field'
require 'hocon/impl/config_node_single_token'
require 'hocon/impl/tokens'

class Hocon::Impl::ConfigNodeObject
  include Hocon::Impl::ConfigNodeComplexValue

  ConfigSyntax = Hocon::ConfigSyntax
  Tokens = Hocon::Impl::Tokens

  def new_node(nodes)
    self.class.new(nodes)
  end

  def has_value(desired_path)
    @children.each do |node|
      if node.is_a?(Hocon::Impl::ConfigNodeField)
        field = node
        key = field.path.value
        if key == desired_path || key.starts_with(desired_path)
          return true
        elsif desired_path.starts_with(key)
          if field.value.is_a?(self.class)
            obj = field.value
            remaining_path = desired_path.sub_path_to_end(key.length)
            if obj.has_value(remaining_path)
              return true
            end
          end
        end
      end
    end
    false
  end

  def change_value_on_path(desired_path, value, flavor)
    children_copy = @children.clone
    seen_non_matching = false
    # Copy the value so we can change it to null but not modify the original parameter
    value_copy = value
    i = children_copy.size
    while i >= 0 do
      if children_copy[i].is_a?(Hocon::Impl::ConfigNodeSingleToken)
        t = children_copy[i].token
        # Ensure that, when we are removing settings in JSON, we don't end up with a trailing comma
        if flavor.equal?(ConfigSyntax::JSON) && !seen_non_matching && t.equal?(Tokens::COMMA)
          children_copy.delete_at(i)
        end
        i -= 1
        next
      elsif !children_copy[i].is_a?(Hocon::Impl::ConfigNodeField)
        i -= 1
        next
      end
      node = children_copy[i]
      key = node.path.value

      # Delete all multi-element paths that start with the desired path, since technically they are duplicates
      if (value_copy.nil? && key == desired_path) || (key.starts_with(desired_path) && !(key == desired_path))
        children_copy.delete_at(i)
        # Remove any whitespace or commas after the deleted setting
        j = i
        while j < children_copy.size
          if children_copy[j].is_a?(Hocon::Impl::ConfigNodeSingleToken)
            t = children_copy[j].token
            if Tokens.ignored_whitespace?(t) || t.equal?(Tokens::COMMA)
              children_copy.delete_at(j)
              j -= 1
            else
              break
            end
          else
            break
          end
          j += 1
        end
      elsif key == desired_path
        seen_non_matching = true
        before = i - 1 > 0 ? children_copy[i - 1] : nil
        if value.is_a?(Hocon::Impl::ConfigNodeComplexValue) && before.is_a?(Hocon::Impl::ConfigNodeSingleToken) &&
            Tokens.ignored_whitespace?(before.token)
          indented_value = value.indent_text(before)
        else
          indented_value = value
        end
        children_copy[i] = node.replace_value(indented_value)
        value_copy = nil
      elsif desired_path.starts_with(key)
        seen_non_matching = true
        if node.value.is_a?(self.class)
          remaining_path = desired_path.sub_path_to_end(key.length)
          children_copy[i] = node.replace_value(node.value.change_value_on_path(remaining_path, value_copy, flavor))
          if !value_copy.nil? && !(node == @children[i])
            value_copy = nil
          end
        end
      else
        seen_non_matching = true
      end
      i -= 1
    end
    self.class.new(children_copy)
  end

  def set_value_on_path(desired_path, value, flavor = ConfigSyntax::CONF)
    path = Hocon::Impl::PathParser.parse_path_node(desired_path, flavor)
    set_value_on_path_node(path, value, flavor)
  end

  def set_value_on_path_node(desired_path, value, flavor)
    node = change_value_on_path(desired_path.value, value, flavor)

    # If the desired Path did not exist, add it
    unless node.has_value(desired_path.value)
      return node.add_value_on_path(desired_path, value, flavor)
    end
    node
  end

  def indentation
    seen_new_line = false
    indentation = []

    if @children.empty?
      return indentation
    end

    @children.each_index do |i|
      unless seen_new_line
        if @children[i].is_a?(Hocon::Impl::ConfigNodeSingleToken) && Tokens.newline?(@children[i].token)
          seen_new_line = true
          indentation.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens.new_line(nil)))
        end
      else
        if @children[i].is_a?(Hocon::Impl::ConfigNodeSingleToken) &&
            Tokens.ignored_whitespace?(@children[i].token) &&
            i + 1 < @children.size &&
            (@children[i + 1].is_a?(Hocon::Impl::ConfigNodeField) || @children[i + 1].is_a?(Hocon::Impl::ConfigNodeInclude))
          # Return the indentation of the first setting on its own line
          indentation.push(@children[i])
          return indentation
        end
      end
    end
    if indentation.empty?
      indentation.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens.new_ignored_whitespace(nil, " ")))
      return indentation
    else
      # Calculate the indentation of the ending curly-brace to get the indentation of the root object
      last = @children[-1]
      if last.is_a?(Hocon::Impl::ConfigNodeSingleToken) && last.token.equal?(Tokens::CLOSE_CURLY)
        beforeLast = @children[-2]
        indent = ""
        if beforeLast.is_a?(Hocon::Impl::ConfigNodeSingleToken) &&
            Tokens.ignored_whitespace?(beforeLast.token)
          indent = beforeLast.token.token_text
        end
        indent += "  "
        indentation.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens.new_ignored_whitespace(nil, indent)))
        return indentation
      end
    end

    # The object has no curly braces and is at the root level, so don't indent
    indentation
  end

  def add_value_on_path(desired_path, value, flavor)
    path = desired_path.value
    children_copy = @children.clone
    indentation = indentation().clone

    # If the value we're inserting is a complex value, we'll need to indent it for insertion
    if value.is_a?(Hocon::Impl::ConfigNodeComplexValue) && indentation.length > 0
      indented_value = value.indent_text(indentation[-1])
    else
      indented_value = value
    end
    same_line = !(indentation.length > 0 && indentation[0].is_a?(Hocon::Impl::ConfigNodeSingleToken) &&
                    Tokens.newline?(indentation[0].token))

    # If the path is of length greater than one, see if the value needs to be added further down
    if path.length > 1
       (0..@children.size - 1).reverse_each do |i|
        unless @children[i].is_a?(Hocon::Impl::ConfigNodeField)
          next
        end
        node = @children[i]
        key = node.path.value
        if path.starts_with(key) && node.value.is_a?(self.class)
          remaining_path = desired_path.sub_path(key.length)
          new_value = node.value
          children_copy[i] = node.replace_value(new_value.add_value_on_path(remaining_path, value, flavor))
          return self.class.new(children_copy)
        end
      end
    end

    # Otherwise, construct the new setting
    starts_with_brace = @children[0].is_a?(Hocon::Impl::ConfigNodeSingleToken) && @children[0].token.equal?(Tokens::OPEN_CURLY)
    new_nodes = []
    new_nodes += indentation
    new_nodes.push(desired_path.first)
    new_nodes.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens::COLON))
    new_nodes.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens.new_ignored_whitespace(nil, ' ')))

    if path.length == 1
      new_nodes.push(indented_value)
    else
      # If the path is of length greater than one add the required new objects along the path
      new_object_nodes = []
      new_object_nodes.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens::OPEN_CURLY))
      if indentation.empty?
        new_object_nodes.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens.new_line(nil)))
      end
      new_object_nodes += indentation
      new_object_nodes.push(Hocon::Impl::ConfigNodeSingleToken.new(Tokens::CLOSE_CURLY))
      new_object = self.class.new(new_object_nodes)
      new_nodes.push(new_object.add_value_on_path(desired_path.sub_path(1), indented_value, flavor))
    end

    # Combine these two cases so that we only have to iterate once
    if flavor.equal?(ConfigSyntax::JSON) || starts_with_brace || same_line
      i = children_copy.size - 1
      while i >= 0

        # If we are in JSON or are adding a setting on the same line, we need to add a comma to the
        # last setting
        if (flavor.equal?(ConfigSyntax::JSON) || same_line) && children_copy[i].is_a?(Hocon::Impl::ConfigNodeField)
          if i + 1 >= children_copy.size ||
              !(children_copy[i + 1].is_a?(Hocon::Impl::ConfigNodeSingleToken) && children_copy[i + 1].token.equal?(Tokens::COMMA))
            children_copy.insert(i + 1, Hocon::Impl::ConfigNodeSingleToken.new(Tokens::COMMA))
            break
          end
        end

        # Add the value into the copy of the children map, keeping any whitespace/newlines
        # before the close curly brace
        if starts_with_brace && children_copy[i].is_a?(Hocon::Impl::ConfigNodeSingleToken) &&
            children_copy[i].token == Tokens::CLOSE_CURLY
          previous = children_copy[i - 1]
          if previous.is_a?(Hocon::Impl::ConfigNodeSingleToken) && Tokens.newline?(previous.token)
            children_copy.insert(i - 1, Hocon::Impl::ConfigNodeField.new(new_nodes))
            i -= 1
          elsif previous.is_a?(Hocon::Impl::ConfigNodeSingleToken) && Tokens.ignored_whitespace?(previous.token)
            before_previous = children_copy[i - 2]
            if same_line
              children_copy.insert(i - 1, Hocon::Impl::ConfigNodeField.new(new_nodes))
              i -= 1
            elsif before_previous.is_a?(Hocon::Impl::ConfigNodeSingleToken) && Tokens.newline?(before_previous.token)
              children_copy.insert(i - 2, Hocon::Impl::ConfigNodeField.new(new_nodes))
              i -= 2
            else
              children_copy.insert(i, Hocon::Impl::ConfigNodeField.new(new_nodes))
            end
          else
            children_copy.insert(i, Hocon::Impl::ConfigNodeField.new(new_nodes))
          end
        end

        i -= 1
      end
    end
    unless starts_with_brace
      if children_copy[-1].is_a?(Hocon::Impl::ConfigNodeSingleToken) && Tokens.newline?(children_copy[-1].token)
        children_copy.insert(-2, Hocon::Impl::ConfigNodeField.new(new_nodes))
      else
        children_copy.push(Hocon::Impl::ConfigNodeField.new(new_nodes))
      end
    end
    self.class.new(children_copy)
  end

  def remove_value_on_path(desired_path, flavor)
    path = Hocon::Impl::PathParser.parse_path_node(desired_path, flavor).value
    change_value_on_path(path, nil, flavor)
  end
end
