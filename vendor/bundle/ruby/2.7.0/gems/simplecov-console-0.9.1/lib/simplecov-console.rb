require 'ansi/code'

class SimpleCov::Formatter::Console

  VERSION = IO.read(File.expand_path("../../VERSION", __FILE__)).strip

  ATTRIBUTES = [:table_options, :use_colors, :max_rows, :max_lines,
    :missing_len, :show_covered, :sort, :output_style]

  class << self
    attr_accessor(*ATTRIBUTES)
  end

  # enable colors unless NO_COLOR=1
  SimpleCov::Formatter::Console.use_colors =
    (ENV['NO_COLOR'].nil? or ENV['NO_COLOR'].empty?) ? true : false

  # configure max rows from MAX_ROWS env var
  SimpleCov::Formatter::Console.max_rows = ENV.fetch('MAX_ROWS', 15).to_i

  # configure max lines per row and missing len
  SimpleCov::Formatter::Console.max_lines = ENV.fetch('MAX_LINES', 0).to_i
  SimpleCov::Formatter::Console.missing_len = ENV.fetch('MISSING_LEN', 0).to_i

  # configure show_covered from SHOW_COVERED env var
  SimpleCov::Formatter::Console.show_covered = ENV.fetch('SHOW_COVERED', 'false') == 'true'

  # configure sort from SORT env var
  SimpleCov::Formatter::Console.sort = ENV.fetch('SORT', 'coverage')

  # configure output format ('table', 'block')
  SimpleCov::Formatter::Console.output_style = ENV.fetch('OUTPUT_STYLE', 'table')

  def include_output_style
    if SimpleCov::Formatter::Console.output_style == 'block' then
      require 'simplecov-console/output/block'
      extend BlockOutput
    else
      # default to table
      require 'simplecov-console/output/table'
      extend TableOutput
    end
  end

  def show_branch_coverage?(result)
    Gem::Version.new(SimpleCov::VERSION) >= Gem::Version.new('0.18.5') &&
      result.coverage_statistics[:branch]
  end

  def format(result)
    include_output_style

    root = nil
    if Module.const_defined? :ROOT then
      root = ROOT
    elsif Module.const_defined?(:Rails) && Rails.respond_to?(:root) then
      root = Rails.root.to_s
    elsif ENV["BUNDLE_GEMFILE"] then
      root = File.dirname(ENV["BUNDLE_GEMFILE"])
    else
      root = Dir.pwd
    end

    puts
    puts "COVERAGE: #{colorize(pct(result.covered_percent))} -- #{result.covered_lines}/#{result.total_lines} lines in #{result.files.size} files"
    show_branch_coverage = show_branch_coverage?(result)
    if show_branch_coverage
      puts "BRANCH COVERAGE: #{colorize(pct(result.coverage_statistics[:branch].percent))} -- #{result.covered_branches}/#{result.total_branches} branches in #{result.files.size} branches"
    end
    puts

    if root.nil? then
      return
    end

    if SimpleCov::Formatter::Console.sort == 'coverage'
      if show_branch_coverage
        files = result.files.sort do |a,b|
          (a.covered_percent <=> b.covered_percent).nonzero? ||
            (a.coverage_statistics[:branch].percent <=> b.coverage_statistics[:branch].percent)
        end
      else
        files = result.files.sort_by(&:covered_percent)
      end
    else
      files = result.files.to_a
    end

    covered_files = 0

    unless SimpleCov::Formatter::Console.show_covered
      files.select!{ |file|
        if file.covered_percent == 100 && (!show_branch_coverage || file.coverage_statistics[:branch].percent == 100) then
          covered_files += 1
          false
        else
          true
        end
      }
      if files.nil? or files.empty? then
        return
      end
    end

    max_rows = SimpleCov::Formatter::Console.max_rows

    if ![-1, nil].include?(max_rows) && files.size > max_rows then
      puts "showing bottom (worst) #{max_rows} of #{files.size} files"
      files = files.slice(0, max_rows)
    end

    puts output(files, root, show_branch_coverage)

    if covered_files > 0 then
      puts "#{covered_files} file(s) with 100% coverage not shown"
    end

  end

  def branches_missed(missed_branches)
    missed_branches.group_by(&:start_line).map do |line_number, branches|
      "#{line_number}[#{branches.map(&:type).join(',')}]"
    end
  end

  # Group missed lines for better display
  #
  # @param [Array<SimpleCov::SourceFile::Line>] missed    array of missed lines reported by SimpleCov
  #
  # @return [Array<String>] Missing groups of lines
  def missed(missed_lines)
    groups = {}
    base = nil
    previous = nil
    missed_lines.each do |src|
      ln = src.line_number
      if base && previous && (ln - 1) == previous
        groups[base] += 1
        previous = ln
      else
        base = ln
        groups[base] = 0
        previous = base
      end
    end

    group_str = []
    groups.map do |starting_line, length|
      if length > 0
        group_str << "#{starting_line}-#{starting_line + length}"
      else
        group_str << "#{starting_line}"
      end
    end

    max_lines = SimpleCov::Formatter::Console.max_lines
    if max_lines > 0 && group_str.size > max_lines then
      # Show at most N missing groups of lines
      group_str = group_str[0, SimpleCov::Formatter::Console.max_lines] << "..."
    end

    group_str
  end

  # Truncate string to at most N chars (as defined by missing_len)
  def trunc(str)
    return str if str.include?("...") # already truncated, skip

    len = SimpleCov::Formatter::Console.missing_len
    if len > 0 && str.size > len then
      str = str[0, len].gsub(/,(\s+)?$/, '') + ' ...'
    end
    str
  end

  def pct(number)
    sprintf("%6.2f%%", number)
  end

  def use_colors?
    SimpleCov::Formatter::Console.use_colors
  end

  def colorize(s)
    return s if !use_colors?

    s =~ /([\d.]+)/
    n = $1.to_f
    if n >= 90 then
      ANSI.green { s }
    elsif n >= 80 then
      ANSI.yellow { s }
    else
      ANSI.red { s }
    end
  end
end
