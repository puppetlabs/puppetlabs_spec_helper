module FakeFS
  # Fake Dir class
  class FakeDir
    attr_accessor :name, :parent, :mode, :uid, :gid, :mtime, :atime, :inode
    attr_reader :ctime, :content

    def initialize(name = nil, parent = nil)
      @name    = name
      @parent  = parent
      @ctime   = Time.now
      @mtime   = @ctime
      @atime   = @ctime
      @mode    = 0o100000 + (0o777 - File.umask)
      @uid     = Process.uid
      @gid     = Process.gid
      @inode   = FakeInode.new(self)
      @content = ''
      @entries = {}
    end

    def entry
      self
    end

    def inspect
      "(FakeDir name:#{name.inspect} " \
      "parent:#{parent.to_s.inspect} size:#{@entries.size})"
    end

    def clone(parent = nil)
      clone = Marshal.load(Marshal.dump(self))
      clone.entries.each do |value|
        value.parent = clone
      end
      clone.parent = parent if parent
      clone.inode = @inode.clone
      clone
    end

    def to_s
      if parent && parent.to_s != '.'
        File.join(parent.to_s, name)
      elsif parent && parent.to_s == '.'
        "#{File::PATH_SEPARATOR}#{name}"
      else
        name
      end
    end

    def empty?
      @entries.empty?
    end

    def entries
      @entries.values
    end

    def matches(pattern)
      @entries.select { |k, _v| pattern =~ k }.values
    end

    def [](name)
      @entries[name]
    end

    def []=(name, value)
      @entries[name] = value
    end

    def delete(node = self)
      if node == self
        parent.delete(self)
        @inode.free_inode_num
      else
        @entries.delete(node.name)
      end
    end
  end
end
