require 'helper'

class TestSimplecovConsole < MiniTest::Test

  # mock for SimpleCov::SourceFile::Line
  Line = Struct.new(:line_number)

  # mock for SimpleCov::SourceFile
  SourceFile = Struct.new(
    :filename,
    :lines_of_code,
    :covered_lines,
    :missed_lines,
    :covered_percent
  )

  CoverageStatistics = Struct.new(
    :percent
  )

  Branch = Struct.new(
    :start_line,
    :type
  )

  SourceFileWithBranches = Struct.new(
    :filename,
    :lines_of_code,
    :covered_lines,
    :missed_lines,
    :covered_percent,
    :coverage_statistics,
    :total_branches,
    :missed_branches
  )

  def setup
    @console = SimpleCov::Formatter::Console.new
  end

  def teardown
    SimpleCov::Formatter::Console.output_style = 'table'
    SimpleCov::Formatter::Console.max_lines = 0
  end

  def test_defined
    assert defined?(SimpleCov::Formatter::Console)
    assert defined?(SimpleCov::Formatter::Console::VERSION)
  end

  def test_missed
    missed_lines = [Line.new(1), Line.new(2),
                    Line.new(3), Line.new(5)]
    expected_result = ["1-3", "5"]
    assert_equal expected_result, @console.missed(missed_lines)
  end

  def test_max_missed
    SimpleCov::Formatter::Console.max_lines = 1
    missed_lines = [Line.new(1), Line.new(2),
                    Line.new(3), Line.new(5)]
    expected_result = ["1-3", "..."]
    assert_equal expected_result, @console.missed(missed_lines)

    SimpleCov::Formatter::Console.max_lines = 3
    expected_result = ["1-3", "5"]
    assert_equal expected_result, @console.missed(missed_lines)
  end

  def test_table_output
    SimpleCov::Formatter::Console.output_style = 'table'
    @console.include_output_style
    files = [
      SourceFile.new('foo.rb',5,[2,3],[Line.new(1), Line.new(4), Line.new(5)],40.0)
    ]
    actual = @console.output(files,'/',false)
    assert actual.is_a? Terminal::Table
    assert_equal 1, actual.rows.count
  end

  def test_table_output_with_branches
    SimpleCov::Formatter::Console.output_style = 'table'
    @console.include_output_style
    files = [
      SourceFileWithBranches.new(
        'foo.rb',5,[2,3],[Line.new(1), Line.new(4), Line.new(5)],40.0,
        {branch: CoverageStatistics.new(50.0)}, [1,2],
        [Branch.new(2, :then)]
      )
    ]
    actual = @console.output(files,'/',true)
    assert actual.is_a? Terminal::Table
    assert_equal 1, actual.rows.count
  end

  def test_block_output
    SimpleCov::Formatter::Console.use_colors = false
    SimpleCov::Formatter::Console.output_style = 'block'
    @console.include_output_style

    files = [
      SourceFile.new('foo.rb',5,[2,3],[Line.new(1), Line.new(4), Line.new(5)],40.0)
    ]
    expected = "\n    file: foo.rb\ncoverage: 40.00% (2/5 lines)\n  missed: 1, 4-5\n\n"
    assert_equal expected, @console.output(files,'/',false)
  end

  def test_block_output_with_branches
    SimpleCov::Formatter::Console.use_colors = false
    SimpleCov::Formatter::Console.output_style = 'block'
    @console.include_output_style
    files = [
      SourceFileWithBranches.new(
        'foo.rb',5,[2,3],[Line.new(1), Line.new(4), Line.new(5)],40.0,
        {branch: CoverageStatistics.new(50.0)}, [1,2],
        [Branch.new(2, :then)]
      )
    ]
    expected = "\n    file: foo.rb\ncoverage: 40.00% (2/5 lines)\n  missed: 1, 4-5\nbranches: 50.00% (1/2 branches)\n  missed: 2[then]\n\n"
    assert_equal expected, @console.output(files,'/',true)
  end
end
