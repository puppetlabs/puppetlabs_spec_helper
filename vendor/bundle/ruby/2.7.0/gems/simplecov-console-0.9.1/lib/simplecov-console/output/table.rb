require 'terminal-table'

class SimpleCov::Formatter::Console
  module TableOutput

    # format per-file results output using Terminal::Table
    def output(files, root,show_branch)
      table = files.map do |f|
        row = [
          colorize(pct(f.covered_percent)),
          f.filename.gsub(root + "/", ''),
          f.lines_of_code,
          f.missed_lines.count,
          trunc(missed(f.missed_lines).join(", ")),
        ]
        if show_branch
          row += [
            colorize(pct(f.coverage_statistics[:branch].percent)),
            f.total_branches.count,
            f.missed_branches.count,
            branches_missed(f.missed_branches).join(", ")
          ]
        end

        row
      end

      table_options = SimpleCov::Formatter::Console.table_options || {}
      if !table_options.kind_of?(Hash) then
        raise ArgumentError.new("SimpleCov::Formatter::Console.table_options must be a Hash")
      end

      headings = %w{ coverage file lines missed missing }
      if show_branch
        headings += [
          'branch coverage',
          'branches',
          'branches missed',
          'branches missing'
        ]
      end

      opts = table_options.merge({:headings => headings, :rows => table})
      Terminal::Table.new(opts)
    end

  end
end
