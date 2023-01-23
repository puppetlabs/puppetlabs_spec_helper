# encoding: utf-8

require 'hocon/impl'

module Hocon::Impl::OriginType
  ## for now, we only support a subset of these
  GENERIC = 0
  FILE = 1
  #URL = 2
  # We don't actually support loading from the classpath / loadpath, which is
  # what 'RESOURCE' is about in the upstream library.  However, some code paths
  # still flow through our simplistic implementation of `ParseableResource`, so
  # we need this constant.
  RESOURCE = 3
end
