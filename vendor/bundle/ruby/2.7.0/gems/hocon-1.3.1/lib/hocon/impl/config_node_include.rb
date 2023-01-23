# encoding: utf-8

require 'hocon/impl'
require 'hocon/config_error'
require 'hocon/impl/abstract_config_node'
require 'hocon/impl/config_node_simple_value'

class Hocon::Impl::ConfigNodeInclude
  include Hocon::Impl::AbstractConfigNode
  def initialize(children, kind)
    @children = children
    @kind = kind
  end

  attr_reader :kind, :children

  def tokens
    tokens = []
    @children.each do |child|
      tokens += child.tokens
    end
    tokens
  end

  def name
    @children.each do |child|
      if child.is_a?(Hocon::Impl::ConfigNodeSimpleValue)
        return Hocon::Impl::Tokens.value(child.token).unwrapped
      end
    end
    nil
  end
end