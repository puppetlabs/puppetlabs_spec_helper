# encoding: utf-8

require 'hocon'

module Hocon::ConfigSyntax
  JSON = 0
  CONF = 1
  # alias 'HOCON' to 'CONF' since some users may be more familiar with that
  HOCON = 1
  # we're not going to try to support .properties files any time soon :)
  #PROPERTIES = 2
end
