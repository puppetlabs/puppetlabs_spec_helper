# encoding: utf-8

require 'hocon/impl'
require 'hocon/config_error'

module Hocon::Impl::FromMapMode
  KEYS_ARE_PATHS = 0
  KEYS_ARE_KEYS = 1
  ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError

  def self.map_mode_name(from_map_mode)
    case from_map_mode
      when KEYS_ARE_PATHS then "KEYS_ARE_PATHS"
      when KEYS_ARE_KEYS then "KEYS_ARE_KEYS"
      else raise ConfigBugOrBrokenError.new("Unrecognized FromMapMode #{from_map_mode}")
    end
  end
end