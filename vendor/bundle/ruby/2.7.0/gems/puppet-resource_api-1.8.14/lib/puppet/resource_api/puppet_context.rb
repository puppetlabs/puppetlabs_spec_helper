# frozen_string_literal: true

require 'puppet/resource_api/base_context'
require 'puppet/util/logging'

# Implement Resource API Context to log through Puppet facilities
# and access/expose the puppet process' current device/transport
class Puppet::ResourceApi::PuppetContext < Puppet::ResourceApi::BaseContext
  def device
    # TODO: evaluate facter_url setting for loading config if there is no `current` NetworkDevice
    raise 'no device configured' unless Puppet::Util::NetworkDevice.current
    Puppet::Util::NetworkDevice.current
  end

  def transport
    device.transport
  end

  def log_exception(exception, message: 'Error encountered', trace: false)
    super(exception, message: message, trace: trace || Puppet[:trace])
  end

  protected

  def send_log(level, message)
    Puppet::Util::Log.create(level: level, message: message)
  end
end
