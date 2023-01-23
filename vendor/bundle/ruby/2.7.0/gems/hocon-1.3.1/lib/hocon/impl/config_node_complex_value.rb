# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/abstract_config_node_value'
require 'hocon/impl/config_node_field'
require 'hocon/impl/config_node_include'
require 'hocon/impl/config_node_single_token'
require 'hocon/impl/tokens'
require 'hocon/config_error'

module Hocon::Impl::ConfigNodeComplexValue
  include Hocon::Impl::AbstractConfigNodeValue
  def initialize(children)
    @children = children
  end

  attr_reader :children

  def tokens
    tokens = []
    @children.each do |child|
      tokens += child.tokens
    end
    tokens
  end

  def indent_text(indentation)
    children_copy = @children.clone
    i = 0
    while i < children_copy.size
      child = children_copy[i]
      if child.is_a?(Hocon::Impl::ConfigNodeSingleToken) && Hocon::Impl::Tokens.newline?(child.token)
        children_copy.insert(i + 1, indentation)
        i += 1
      elsif child.is_a?(Hocon::Impl::ConfigNodeField)
        value = child.value
        if value.is_a?(Hocon::Impl::ConfigNodeComplexValue)
          children_copy[i] = child.replace_value(value.indent_text(indentation))
        end
      elsif child.is_a?(Hocon::Impl::ConfigNodeComplexValue)
        children_copy[i] = child.indent_text(indentation)
      end
      i += 1
    end
    new_node(children_copy)
  end

  # This method will just call into the object's constructor, but it's needed
  # for use in the indentText() method so we can avoid a gross if/else statement
  # checking the type of this
  def new_node(nodes)
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "subclasses of ConfigNodeComplexValue should override `new_node` (#{self.class})"
  end
end