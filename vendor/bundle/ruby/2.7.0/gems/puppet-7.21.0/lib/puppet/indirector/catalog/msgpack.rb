require_relative '../../../puppet/resource/catalog'
require_relative '../../../puppet/indirector/msgpack'

class Puppet::Resource::Catalog::Msgpack < Puppet::Indirector::Msgpack
  desc "Store catalogs as flat files, serialized using MessagePack."
end
