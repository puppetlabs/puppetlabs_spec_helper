# frozen_string_literal: true
require_relative '../../puppet/parser/files'
require 'erb'
require_relative '../../puppet/file_system'

# A simple wrapper for templates, so they don't have full access to
# the scope objects.
#
# @api private
class Puppet::Parser::TemplateWrapper
  include Puppet::Util
  Puppet::Util.logmethods(self)

  def initialize(scope)
    @__scope__ = scope
  end

  # @return [String] The full path name of the template that is being executed
  # @api public
  def file
    @__file__
  end

  # @return [Puppet::Parser::Scope] The scope in which the template is evaluated
  # @api public
  def scope
    @__scope__
  end

  # Find which line in the template (if any) we were called from.
  # @return [String] the line number
  # @api private
  def script_line
    identifier = Regexp.escape(@__file__ || "(erb)")
    (caller.find { |l| l =~ /#{identifier}:/ }||"")[/:(\d+):/,1]
  end
  private :script_line

  # Should return true if a variable is defined, false if it is not
  # @api public
  def has_variable?(name)
    scope.include?(name.to_s)
  end

  # @return [Array<String>] The list of defined classes
  # @api public
  def classes
    scope.catalog.classes
  end

  # @return [Array<String>] The tags defined in the current scope
  # @api public
  def tags
    raise NotImplementedError, "Call 'all_tags' instead."
  end

  # @return [Array<String>] All the defined tags
  # @api public
  def all_tags
    scope.catalog.tags
  end

  # @api private
  def file=(filename)
    @__file__ = Puppet::Parser::Files.find_template(filename, scope.compiler.environment)
    unless @__file__
      raise Puppet::ParseError, _("Could not find template '%{filename}'") % { filename: filename }
    end
  end

  # @api private
  def result(string = nil)
    if string
      template_source = "inline template"
    else
      string = Puppet::FileSystem.read_preserve_line_endings(@__file__)
      template_source = @__file__
    end

    # Expose all the variables in our scope as instance variables of the
    # current object, making it possible to access them without conflict
    # to the regular methods.
    escaped_template_source = template_source.gsub(/%/, '%%')
    benchmark(:debug, _("Bound template variables for %{template_source} in %%{seconds} seconds") % { template_source: escaped_template_source }) do
      scope.to_hash.each do |name, value|
        realname = name.gsub(/[^\w]/, "_")
        instance_variable_set("@#{realname}", value)
      end
    end

    result = nil
    benchmark(:debug, _("Interpolated template %{template_source} in %%{seconds} seconds") % { template_source: escaped_template_source }) do
      template = Puppet::Util.create_erb(string)
      template.filename = @__file__
      result = template.result(binding)
    end

    result
  end

  def to_s
    "template[#{(@__file__ ? @__file__ : "inline")}]"
  end
end
