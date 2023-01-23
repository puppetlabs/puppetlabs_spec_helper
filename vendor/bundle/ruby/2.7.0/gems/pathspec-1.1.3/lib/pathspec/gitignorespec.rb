require 'pathspec/regexspec'

class PathSpec
  # Class for parsing a .gitignore spec
  class GitIgnoreSpec < RegexSpec
    attr_reader :regex, :pattern

    def initialize(original_pattern) # rubocop:disable Metrics/CyclomaticComplexity
      pattern = original_pattern.strip unless original_pattern.nil?

      # A pattern starting with a hash ('#') serves as a comment
      # (neither includes nor excludes files). Escape the hash with a
      # back-slash to match a literal hash (i.e., '\#').
      if pattern.start_with?('#')
        @regex = nil
        @inclusive = nil

        # A blank pattern is a null-operation (neither includes nor
        # excludes files).
      elsif pattern.empty? # rubocop:disable Lint/DuplicateBranch
        @regex = nil
        @inclusive = nil

        # Patterns containing three or more consecutive stars are invalid and
        # will be ignored.
      elsif /\*\*\*+/.match?(pattern) # rubocop:disable Lint/DuplicateBranch
        @regex = nil
        @inclusive = nil

        # EDGE CASE: According to git check-ignore (v2.4.1)), a single '/'
        # does not match any file
      elsif pattern == '/' # rubocop:disable Lint/DuplicateBranch
        @regex = nil
        @inclusive = nil

        # We have a valid pattern!
      else
        # A pattern starting with an exclamation mark ('!') negates the
        # pattern (exclude instead of include). Escape the exclamation
        # mark with a back-slash to match a literal exclamation mark
        # (i.e., '\!').
        if pattern.start_with?('!')
          @inclusive = false
          # Remove leading exclamation mark.
          pattern = pattern[1..]
        else
          @inclusive = true
        end

        # Remove leading back-slash escape for escaped hash ('#') or
        # exclamation mark ('!').
        pattern = pattern[1..] if pattern.start_with?('\\')

        # Split pattern into segments. -1 to allow trailing slashes.
        pattern_segs = pattern.split('/', -1)

        # Normalize pattern to make processing easier.

        # A pattern beginning with a slash ('/') will only match paths
        # directly on the root directory instead of any descendant
        # paths. So, remove empty first segment to make pattern relative
        # to root.
        if pattern_segs[0].empty?
          pattern_segs.shift
        elsif pattern_segs.length == 1 ||
              pattern_segs.length == 2 && pattern_segs[-1].empty?
          # A pattern without a beginning slash ('/') will match any
          # descendant path. This is equivilent to "**/{pattern}". So,
          # prepend with double-asterisks to make pattern relative to
          # root.
          # EDGE CASE: This also holds for a single pattern with a
          # trailing slash (e.g. dir/).
          pattern_segs.insert(0, '**') if pattern_segs[0] != '**'
        end

        # A pattern ending with a slash ('/') will match all descendant
        # paths of if it is a directory but not if it is a regular file.
        # This is equivilent to "{pattern}/**". So, set last segment to
        # double asterisks to include all descendants.
        pattern_segs[-1] = '**' if pattern_segs[-1].empty? && pattern_segs.length > 1

        # Handle platforms with backslash separated paths
        path_sep = if File::SEPARATOR == '\\'
                     '\\\\'
                   else
                     '/'
                   end

        # Build regular expression from pattern.
        regex = '^'
        need_slash = false
        regex_end = pattern_segs.size - 1
        pattern_segs.each_index do |i|
          seg = pattern_segs[i]

          case seg
          when '**'
            # A pattern consisting solely of double-asterisks ('**')
            # will match every path.
            if i == 0 && i == regex_end
              regex.concat('.+')

              # A normalized pattern beginning with double-asterisks
              # ('**') will match any leading path segments.
            elsif i == 0
              regex.concat("(?:.+#{path_sep})?")
              need_slash = false

              # A normalized pattern ending with double-asterisks ('**')
              # will match any trailing path segments.
            elsif i == regex_end
              regex.concat("#{path_sep}.*")

              # A pattern with inner double-asterisks ('**') will match
              # multiple (or zero) inner path segments.
            else
              regex.concat("(?:#{path_sep}.+)?")
              need_slash = true
            end

            # Match single path segment.
          when '*'
            regex.concat(path_sep) if need_slash

            regex.concat("[^#{path_sep}]+")
            need_slash = true

          else
            # Match segment glob pattern.
            regex.concat(path_sep) if need_slash

            regex.concat(translate_segment_glob(seg))

            if i == regex_end && @inclusive
              # A pattern ending without a slash ('/') will match a file
              # or a directory (with paths underneath it).
              # e.g. foo matches: foo, foo/bar, foo/bar/baz, etc.
              # EDGE CASE: However, this does not hold for exclusion cases
              # according to `git check-ignore` (v2.4.1).
              regex.concat("(?:#{path_sep}.*)?")
            end

            need_slash = true
          end
        end

        regex.concat('$')
        super(regex)

        # Copy original pattern
        @pattern = original_pattern.dup
      end
    end

    def translate_segment_glob(pattern)
      # Translates the glob pattern to a regular expression. This is used in
      # the constructor to translate a path segment glob pattern to its
      # corresponding regular expression.
      #
      # *pattern* (``str``) is the glob pattern.
      #
      # Returns the regular expression (``str``).
      #
      # NOTE: This is derived from `fnmatch.translate()` and is similar to
      # the POSIX function `fnmatch()` with the `FNM_PATHNAME` flag set.

      escape = false
      regex = ''
      i = 0

      while i < pattern.size
        # Get next character.
        char = pattern[i].chr
        i += 1

        # Escape the character.
        if escape
          escape = false
          regex += Regexp.escape(char)

          # Escape character, escape next character.
        elsif char == '\\'
          escape = true

          # Multi-character wildcard. Match any string (except slashes),
          # including an empty string.
        elsif char == '*'
          regex += '[^/]*'

          # Single-character wildcard. Match any single character (except
          # a slash).
        elsif char == '?'
          regex += '[^/]'

          # Braket expression wildcard. Except for the beginning
          # exclamation mark, the whole braket expression can be used
          # directly as regex but we have to find where the expression
          # ends.
          # - "[][!]" matchs ']', '[' and '!'.
          # - "[]-]" matchs ']' and '-'.
          # - "[!]a-]" matchs any character except ']', 'a' and '-'.
        elsif char == '['
          j = i
          # Pass brack expression negation.
          j += 1 if j < pattern.size && pattern[j].chr == '!'

          # Pass first closing braket if it is at the beginning of the
          # expression.
          j += 1 if j < pattern.size && pattern[j].chr == ']'

          # Find closing braket. Stop once we reach the end or find it.
          j += 1 while j < pattern.size && pattern[j].chr != ']'

          if j < pattern.size
            expr = '['

            # Braket expression needs to be negated.
            case pattern[i].chr
            when '!'
              expr += '^'
              i += 1

              # POSIX declares that the regex braket expression negation
              # "[^...]" is undefined in a glob pattern. Python's
              # `fnmatch.translate()` escapes the caret ('^') as a
              # literal. To maintain consistency with undefined behavior,
              # I am escaping the '^' as well.
            when '^'
              expr += '\\^'
              i += 1
            end

            # Escape brackets contained within pattern
            if pattern[i].chr == ']' && i != j
              expr += '\]'
              i += 1
            end

            # Build regex braket expression. Escape slashes so they are
            # treated as literal slashes by regex as defined by POSIX.
            expr += pattern[i..j].sub('\\', '\\\\')

            # Add regex braket expression to regex result.
            regex += expr

            # Found end of braket expression. Increment j to be one past
            # the closing braket:
            #
            #  [...]
            #   ^   ^
            #   i   j
            #
            j += 1
            # Set i to one past the closing braket.
            i = j

            # Failed to find closing braket, treat opening braket as a
            # braket literal instead of as an expression.
          else
            regex += '\['
          end

          # Regular character, escape it for regex.
        else
          regex << Regexp.escape(char)
        end
      end

      regex
    end

    def inclusive?
      @inclusive
    end
  end
end
