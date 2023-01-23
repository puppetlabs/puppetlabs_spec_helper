# Puppet package provider for Python's `pip3` package management frontend.
# <http://pip.pypa.io/>

Puppet::Type.type(:package).provide :pip3,
  :parent => :pip do

  desc "Python packages via `pip3`.

  This provider supports the `install_options` attribute, which allows command-line flags to be passed to pip3.
  These options should be specified as an array where each element is either a string or a hash."

  has_feature :installable, :uninstallable, :upgradeable, :versionable, :install_options, :targetable

  def self.cmd
    ["pip3"]
  end
end
