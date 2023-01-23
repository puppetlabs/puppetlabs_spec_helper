Puppet::Type.type(:package).provide :dnf, :parent => :yum do
  desc "Support via `dnf`.

  Using this provider's `uninstallable` feature will not remove dependent packages. To
  remove dependent packages with this provider use the `purgeable` feature, but note this
  feature is destructive and should be used with the utmost care.

  This provider supports the `install_options` attribute, which allows command-line flags to be passed to dnf.
  These options should be specified as an array where each element is either
   a string or a hash."

  has_feature :install_options, :versionable, :virtual_packages, :install_only

  commands :cmd => "dnf", :rpm => "rpm"

  # Note: this confine was borrowed from the Yum provider. The
  # original purpose (from way back in 2007) was to make sure we
  # never try to use RPM on a machine without it. We think this
  # has probably become obsolete with the way `commands` work, so
  # we should investigate removing it at some point.
  if command('rpm')
    confine :true => begin
      rpm('--version')
      rescue Puppet::ExecutionFailure
        false
      else
        true
      end
  end

  defaultfor :operatingsystem => :fedora
  notdefaultfor :operatingsystem => :fedora, :operatingsystemmajrelease => (19..21).to_a
  defaultfor :osfamily => :redhat
  notdefaultfor :osfamily => :redhat, :operatingsystemmajrelease => (4..7).to_a

  def self.update_command
    # In DNF, update is deprecated for upgrade
    'upgrade'
  end

  # The value to pass to DNF as its error output level.
  # DNF differs from Yum slightly with regards to error outputting.
  #
  # @param None
  # @return [String]
  def self.error_level
    '1'
  end
end
