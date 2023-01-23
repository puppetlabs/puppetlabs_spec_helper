class Puppet::Settings::IntegerSetting < Puppet::Settings::BaseSetting
  def munge(value)
    return value if Integer === value

    begin
      value = Integer(value)
    rescue ArgumentError, TypeError
      raise Puppet::Settings::ValidationError, _("Cannot convert '%{value}' to an integer for parameter: %{name}") % { value: value.inspect, name: @name }
    end

    value
  end

  def type
    :integer
  end
end
