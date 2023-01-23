require 'pathspec/gitignorespec'
require 'pathspec/regexspec'
require 'find'
require 'pathname'

# Main PathSpec class, provides interfaces to various spec implementations
class PathSpec
  attr_reader :specs

  def initialize(lines = nil, type = :git)
    @specs = []

    add(lines, type) if lines

    self
  end

  # Check if a path matches the pathspecs described
  # Returns true if there are matches and none are excluded
  # Returns false if there aren't matches or none are included
  def match(path)
    matches = specs_matching(path.to_s)
    !matches.empty? && matches.all? {|m| m.inclusive?}
  end

  def specs_matching(path)
    @specs.select do |spec|
      spec if spec.match(path)
    end
  end

  # Check if any files in a given directory or subdirectories match the specs
  # Returns matched paths or nil if no paths matched
  def match_tree(root)
    rootpath = Pathname.new(root)
    matching = []

    Find.find(root) do |path|
      relpath = Pathname.new(path).relative_path_from(rootpath).to_s
      relpath += '/' if File.directory? path
      matching << path if match(relpath)
    end

    matching
  end

  def match_path(path, root = '/')
    rootpath = Pathname.new(drive_letter_to_path(root))
    relpath = Pathname.new(drive_letter_to_path(path)).relative_path_from(rootpath).to_s
    relpath += '/' if path[-1].chr == '/'

    match(relpath)
  end

  def match_paths(paths, root = '/')
    matching = []

    paths.each do |path|
      matching << path if match_path(path, root)
    end

    matching
  end

  def drive_letter_to_path(path)
    path.gsub(%r{^([a-zA-Z]):/}, '/\1/')
  end

  # Generate specs from a filename, such as a .gitignore
  def self.from_filename(filename, type = :git)
    File.open(filename, 'r') { |io| from_lines(io, type) }
  end

  def self.from_lines(lines, type = :git)
    new lines, type
  end

  # Generate specs from lines of text
  def add(obj, type = :git)
    spec_class = spec_type(type)

    if obj.respond_to?(:each_line)
      obj.each_line do |l|
        spec = spec_class.new(l.rstrip)

        @specs << spec if !spec.regex.nil? && !spec.inclusive?.nil?
      end
    elsif obj.respond_to?(:each)
      obj.each do |l|
        add(l, type)
      end
    else
      raise 'Cannot make Pathspec from non-string/non-enumerable object.'
    end

    self
  end

  def empty?
    @specs.empty?
  end

  def spec_type(type)
    case type
    when :git
      GitIgnoreSpec
    when :regex
      RegexSpec
    else
      raise "Unknown spec type #{type}"
    end
  end
end
