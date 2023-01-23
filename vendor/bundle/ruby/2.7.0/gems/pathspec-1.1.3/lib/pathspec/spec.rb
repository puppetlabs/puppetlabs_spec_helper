class PathSpec
  # Abstract spec
  class Spec
    attr_reader :regex, :pattern

    def initialize(*_); end

    def match(files)
      raise 'Unimplemented'
    end

    def inclusive?
      true
    end

    def to_s
      @pattern
    end
  end
end
