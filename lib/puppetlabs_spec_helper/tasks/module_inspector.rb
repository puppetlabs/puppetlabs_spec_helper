require 'set'
require 'puppet'

module PuppetlabsSpecHelper; end
module PuppetlabsSpecHelper::Tasks; end

class PuppetlabsSpecHelper::Tasks::ModuleInspector
  attr_reader :path

  def initialize(path = Dir.pwd)
    @path = path
  end

  def run
    {
      host_class:   host_classes,
      defined_type: defined_types,
    }
  end

  private

  def manifests
    return [] unless File.directory?(File.join(path, 'manifests'))

    Dir[File.join(path, 'manifests', '**', '*.pp')]
  end

  def manifest_definitions
    @manifest_definitions ||= manifests.map { |r|
      PuppetlabsSpecHelper::Tasks::ManifestInspector.new(r).definitions
    }.flatten
  end

  def host_classes
    remove_type_key(manifest_definitions.select { |r| r[:type] == :host_class })
  end

  def defined_types
    remove_type_key(manifest_definitions.select { |r| r[:type] == :defined_type })
  end

  def remove_type_key(hash)
    hash.map { |r| r.reject { |k, _| k == :type } }
  end
end

class PuppetlabsSpecHelper::Tasks::ManifestInspector
  attr_reader :path

  DEFINITION_CLASSES = Set[
    Puppet::Pops::Model::HostClassDefinition,
    Puppet::Pops::Model::ResourceTypeDefinition,
  ]

  def initialize(path)
    @path = path
  end

  def definitions
    ast.definitions.find_all { |r| DEFINITION_CLASSES.include?(r.class) }.map do |obj|
      obj_type = obj.class.to_s.split('::').last.gsub(%r{([a-z]+)([A-Z][a-z])}, '\1_\2').downcase
      send("handle_#{obj_type}", obj)
    end
  end

  private

  def handle_host_class_definition(obj)
    {
      type:       :host_class,
      file:       path,
      name:       obj.name,
      parameters: obj.parameters.map { |r| handle_parameter(r) },
      parent:     obj.parent_class,
    }
  end

  def handle_resource_type_definition(obj)
    {
      type:       :defined_type,
      file:       path,
      name:       obj.name,
      parameters: obj.parameters.map { |r| handle_parameter(r) },
    }
  end

  def handle_parameter(obj)
    obj.name
  end

  def parser
    Puppet::Pops::Parser::EvaluatingParser.new
  end

  def ast
    @ast ||= begin
               result = parser.parse_file(path)
               result.respond_to?(:model) ? result.model : result
             end
  end
end
