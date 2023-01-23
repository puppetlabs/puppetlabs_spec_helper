# frozen_string_literal: true

require 'puppet/resource_api/base_context'

# Implement Resource API Conext to log through an IO object, defaulting to `$stderr`.
# There is no access to a device here. You can supply a transport if necessary.
class Puppet::ResourceApi::IOContext < Puppet::ResourceApi::BaseContext
  attr_reader :transport

  def initialize(definition, target = $stderr, transport = nil)
    super(definition)
    @target = target
    @transport = transport
  end

  protected

  def send_log(level, message)
    @target.puts "#{level}: #{message}"
  end
end
