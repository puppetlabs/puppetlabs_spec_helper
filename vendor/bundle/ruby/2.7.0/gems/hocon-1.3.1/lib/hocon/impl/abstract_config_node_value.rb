# encoding: utf-8

require 'hocon/impl'
require 'hocon/impl/abstract_config_node'

# This essentially exists in the upstream so we can ensure only certain types of
# config nodes can be passed into some methods. That's not a problem in Ruby, so this is
# unnecessary, but it seems best to keep it around for consistency
module Hocon::Impl::AbstractConfigNodeValue
  include Hocon::Impl::AbstractConfigNode
end