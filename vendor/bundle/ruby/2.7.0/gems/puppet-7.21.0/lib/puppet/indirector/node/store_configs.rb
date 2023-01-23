require_relative '../../../puppet/indirector/store_configs'
require_relative '../../../puppet/node'

class Puppet::Node::StoreConfigs < Puppet::Indirector::StoreConfigs

  desc %q{Part of the "storeconfigs" feature. Should not be directly set by end users.}

end
