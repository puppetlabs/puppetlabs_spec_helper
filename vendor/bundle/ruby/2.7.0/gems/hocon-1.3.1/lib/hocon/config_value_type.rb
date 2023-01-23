# encoding: utf-8

require 'hocon'
require 'hocon/config_error'

#
# The type of a configuration value (following the <a
# href="http://json.org">JSON</a> type schema).
#
module Hocon::ConfigValueType
  OBJECT = 0
  LIST = 1
  NUMBER = 2
  BOOLEAN = 3
  NULL = 4
  STRING = 5

  def self.value_type_name(config_value_type)
    case config_value_type
      when OBJECT then "OBJECT"
      when LIST then "LIST"
      when NUMBER then "NUMBER"
      when BOOLEAN then "BOOLEAN"
      when NULL then "NULL"
      when STRING then "STRING"
      else raise Hocon::ConfigError::ConfigBugOrBrokenError, "Unrecognized value type '#{config_value_type}'"
    end
  end
end
