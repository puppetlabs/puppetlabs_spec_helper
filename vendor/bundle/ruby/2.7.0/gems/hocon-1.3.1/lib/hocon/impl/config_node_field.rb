# encoding: utf-8

require 'hocon/impl'
require 'hocon/config_error'
require 'hocon/impl/abstract_config_node'
require 'hocon/impl/abstract_config_node_value'
require 'hocon/impl/config_node_comment'
require 'hocon/impl/config_node_path'
require 'hocon/impl/config_node_single_token'
require 'hocon/impl/tokens'

class Hocon::Impl::ConfigNodeField
  include Hocon::Impl::AbstractConfigNode

  Tokens = Hocon::Impl::Tokens

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

  def replace_value(new_value)
    children_copy = @children.clone
    children_copy.each_with_index do |child, i|
      if child.is_a?(Hocon::Impl::AbstractConfigNodeValue)
        children_copy[i] = new_value
        return self.class.new(children_copy)
      end
    end
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "Field node doesn't have a value"
  end

  def value
    @children.each do |child|
      if child.is_a?(Hocon::Impl::AbstractConfigNodeValue)
        return child
      end
    end
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "Field node doesn't have a value"
  end

  def path
    @children.each do |child|
      if child.is_a?(Hocon::Impl::ConfigNodePath)
        return child
      end
    end
    raise Hocon::ConfigError::ConfigBugOrBrokenError, "Field node doesn't have a path"
  end

  def separator
    @children.each do |child|
      if child.is_a?(Hocon::Impl::ConfigNodeSingleToken)
        t = child.token
        if t == Tokens::PLUS_EQUALS or t == Tokens::COLON or t == Tokens::EQUALS
          return t
        end
      end
    end
    nil
  end

  def comments
    comments = []
    @children.each do |child|
      if child.is_a?(Hocon::Impl::ConfigNodeComment)
        comments << child.comment_text
      end
    end
    comments
  end
end