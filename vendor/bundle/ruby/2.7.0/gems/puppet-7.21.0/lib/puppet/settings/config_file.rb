require_relative '../../puppet/settings/ini_file'

##
# @api private
#
# Parses puppet configuration files
#
class Puppet::Settings::ConfigFile

  ##
  # @param value_converter [Proc] a function that will convert strings into ruby types
  def initialize(value_converter)
    @value_converter = value_converter
  end

  # @param file [String, File] pointer to the file whose text we are parsing
  # @param text [String] the actual text of the inifile to be parsed
  # @param allowed_section_names [Array] an optional array of accepted section
  #   names; if this list is non-empty, sections outside of it will raise an
  #   error.
  # @return A Struct with a +sections+ array representing each configuration section
  def parse_file(file, text, allowed_section_names = [])
    result = Conf.new
    if !allowed_section_names.empty?
      allowed_section_names << 'main' unless allowed_section_names.include?('main')
    end

    ini = Puppet::Settings::IniFile.parse(text.encode(Encoding::UTF_8))
    unique_sections_in(ini, file, allowed_section_names).each do |section_name|
      section = Section.new(section_name.to_sym)
      result.with_section(section)

      ini.lines_in(section_name).each do |line|
        if line.is_a?(Puppet::Settings::IniFile::SettingLine)
          parse_setting(line, section)
        elsif line.text !~ /^\s*#|^\s*$/
          raise Puppet::Settings::ParseError.new(_("Could not match line %{text}") % { text: line.text }, file, line.line_number)
        end
      end
    end

    result
  end

  Conf = Struct.new(:sections) do
    def initialize
      super({})
    end

    def with_section(section)
      sections[section.name] = section
      self
    end
  end

  Section = Struct.new(:name, :settings) do
    def initialize(name)
      super(name, [])
    end

    def with_setting(name, value, meta)
      settings << Setting.new(name, value, meta)
      self
    end

    def setting(name)
      settings.find { |setting| setting.name == name }
    end
  end

  Setting = Struct.new(:name, :value, :meta) do
    def has_metadata?
      meta != NO_META
    end
  end

  Meta = Struct.new(:owner, :group, :mode)
  NO_META = Meta.new(nil, nil, nil)

private

  def unique_sections_in(ini, file, allowed_section_names)
    ini.section_lines.collect do |section|
      if !allowed_section_names.empty? && !allowed_section_names.include?(section.name)
        error_location_str = Puppet::Util::Errors.error_location(file, section.line_number)
        message = _("Illegal section '%{name}' in config file at %{error_location}.") %
            { name: section.name, error_location: error_location_str }
        #TRANSLATORS 'puppet.conf' is the name of the puppet configuration file and should not be translated.
        message += ' ' + _("The only valid puppet.conf sections are: [%{allowed_sections_list}].") %
            { allowed_sections_list: allowed_section_names.join(", ") }
        message += ' ' + _("Please use the directory environments feature to specify environments.")
        message += ' ' + _("(See https://puppet.com/docs/puppet/latest/environments_about.html)")
        raise(Puppet::Error, message)
      end
      section.name
    end.uniq
  end

  def parse_setting(setting, section)
    var = setting.name.intern
    value = @value_converter[setting.value]

    # Check to see if this is a file argument and it has extra options
    begin
      options = extract_fileinfo(value) if value.is_a?(String)
      if options
        section.with_setting(var, options[:value], Meta.new(options[:owner],
                                                            options[:group],
                                                            options[:mode]))
      else
        section.with_setting(var, value, NO_META)
      end
    rescue Puppet::Error => detail
      raise Puppet::Settings::ParseError.new(detail.message, file, setting.line_number, detail)
    end
  end

  def empty_section
    { :_meta => {} }
  end

  def extract_fileinfo(string)
    result = {}
    value = string.sub(/\{\s*([^}]+)\s*\}/) do
      params = $1
      params.split(/\s*,\s*/).each do |str|
        if str =~ /^\s*(\w+)\s*=\s*([\w]+)\s*$/
          param, value = $1.intern, $2
          result[param] = value
          unless [:owner, :mode, :group].include?(param)
            raise ArgumentError, _("Invalid file option '%{parameter}'") % { parameter: param }
          end

          if param == :mode and value !~ /^\d+$/
            raise ArgumentError, _("File modes must be numbers")
          end
        else
          raise ArgumentError, _("Could not parse '%{string}'") % { string: string }
        end
      end
      ''
    end
    result[:value] = value.sub(/\s*$/, '')
    result
  end
end
