# encoding: utf-8

require 'hocon'

class Hocon::ConfigError < StandardError
  def initialize(origin, message, cause)
    msg =
      if origin.nil?
        message
      else
        "#{origin.description}: #{message}"
      end
    super(msg)
    @origin = origin
    @cause = cause
  end

  class ConfigMissingError < Hocon::ConfigError
  end

  class ConfigNullError < Hocon::ConfigError::ConfigMissingError
    def self.make_message(path, expected)
      if not expected.nil?
        "Configuration key '#{path}' is set to nil but expected #{expected}"
      else
        "Configuration key '#{path}' is nil"
      end
    end
  end

  class ConfigIOError < Hocon::ConfigError
    def initialize(origin, message, cause = nil)
      super(origin, message, cause)
    end
  end

  class ConfigParseError < Hocon::ConfigError
  end

  class ConfigWrongTypeError < Hocon::ConfigError
    def self.with_expected_actual(origin, path, expected, actual, cause = nil)
      ConfigWrongTypeError.new(origin, "#{path} has type #{actual} rather than #{expected}", cause)
    end
  end

  class ConfigBugOrBrokenError < Hocon::ConfigError
    def initialize(message, cause = nil)
      super(nil, message, cause)
    end
  end

  class ConfigNotResolvedError < Hocon::ConfigError::ConfigBugOrBrokenError
  end

  class ConfigBadPathError < Hocon::ConfigError
    def initialize(origin, path, message, cause = nil)
      error_message = !path.nil? ? "Invalid path '#{path}': #{message}" : message
      super(origin, error_message, cause)
    end
  end

  class UnresolvedSubstitutionError < ConfigParseError
    def initialize(origin, detail, cause = nil)
      super(origin, "Could not resolve substitution to a value: " + detail, cause)
    end
  end
end
