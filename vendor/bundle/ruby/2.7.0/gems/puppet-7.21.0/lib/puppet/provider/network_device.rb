
# This is the base class of all prefetched network device provider
class Puppet::Provider::NetworkDevice < Puppet::Provider

  def self.device(url)
    raise "This provider doesn't implement the necessary device method"
  end

  def self.lookup(device, name)
    raise "This provider doesn't implement the necessary lookup method"
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      device = Puppet::Util::NetworkDevice.current || device(resource[:device_url])
      result = lookup(device, name)
      if result
        result[:ensure] = :present
        resource.provider = new(device, result)
      else
        resource.provider = new(device, :ensure => :absent)
      end
    end
  rescue => detail
    # Preserving behavior introduced in #6907
    #TRANSLATORS "prefetch" is a program name and should not be translated
    Puppet.log_exception(detail, _("Could not perform network device prefetch: %{detail}") % { detail: detail })
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  attr_accessor :device

  def initialize(device, *args)
    super(*args)

    @device = device

    # Make a duplicate, so that we have a copy for comparison
    # at the end.
    @properties = @property_hash.dup
  end

  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      val = resource.should(property)
      if val
        @property_hash[property] = val
      end
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def flush
    @property_hash.clear
  end

  def self.instances
  end

  def former_properties
    @properties.dup
  end

  def properties
    @property_hash.dup
  end
end
