# encoding: utf-8

require 'hocon'

class Hocon::ConfigResolveOptions
  attr_reader :use_system_environment, :allow_unresolved

  def initialize(use_system_environment, allow_unresolved)
    @use_system_environment = use_system_environment
    @allow_unresolved = allow_unresolved
  end

  def set_use_system_environment(value)
    self.class.new(value, @allow_unresolved)
  end

  def set_allow_unresolved(value)
    self.class.new(@use_system_environment, value)
  end

  class << self

    def defaults
      self.new(true, false)
    end

    def no_system
      defaults.set_use_system_environment(false)
    end
  end
end
