require 'spec_helper'
require 'puppet/file_serving/metadata'
require 'matchers/json'

describe Puppet::FileServing::Metadata do
  let(:foobar) { File.expand_path('/foo/bar') }

  it "should be a subclass of Base" do
    expect(Puppet::FileServing::Metadata.superclass).to equal(Puppet::FileServing::Base)
  end

  it "should indirect file_metadata" do
    expect(Puppet::FileServing::Metadata.indirection.name).to eq(:file_metadata)
  end

  it "should have a method that triggers attribute collection" do
    expect(Puppet::FileServing::Metadata.new(foobar)).to respond_to(:collect)
  end

  it "should default to json" do
    expect(Puppet::FileServing::Metadata.default_format).to eq(:json)
  end

  it "should support json, pson, yaml" do
    # msgpack is optional, so using include instead of eq
    expect(Puppet::FileServing::Metadata.supported_formats).to include(:json, :pson, :yaml)
  end

  it "should support deserialization" do
    expect(Puppet::FileServing::Metadata).to respond_to(:from_data_hash)
  end

  describe "when serializing" do
    let(:metadata) { Puppet::FileServing::Metadata.new(foobar) }

    it "the data should include the path, relative_path, links, owner, group, mode, checksum, type, and destination" do
      expect(metadata.to_data_hash.keys.sort).to eq(%w{ path relative_path links owner group mode checksum type destination }.sort)
    end

    it "should pass the path in the hash verbatim" do
      expect(metadata.to_data_hash['path']).to eq(metadata.path)
    end

    it "should pass the relative_path in the hash verbatim" do
      expect(metadata.to_data_hash['relative_path']).to eq(metadata.relative_path)
    end

    it "should pass the links in the hash as a string" do
      expect(metadata.to_data_hash['links']).to eq(metadata.links.to_s)
    end

    it "should pass the path owner in the hash verbatim" do
      expect(metadata.to_data_hash['owner']).to eq(metadata.owner)
    end

    it "should pass the group in the hash verbatim" do
      expect(metadata.to_data_hash['group']).to eq(metadata.group)
    end

    it "should pass the mode in the hash verbatim" do
      expect(metadata.to_data_hash['mode']).to eq(metadata.mode)
    end

    it "should pass the ftype in the hash verbatim as the 'type'" do
      expect(metadata.to_data_hash['type']).to eq(metadata.ftype)
    end

    it "should pass the destination verbatim" do
      expect(metadata.to_data_hash['destination']).to eq(metadata.destination)
    end

    it "should pass the checksum in the hash as a nested hash" do
      expect(metadata.to_data_hash['checksum']).to be_is_a(Hash)
    end

    it "should pass the checksum_type in the hash verbatim as the checksum's type" do
      expect(metadata.to_data_hash['checksum']['type']).to eq(metadata.checksum_type)
    end

    it "should pass the checksum in the hash verbatim as the checksum's value" do
      expect(metadata.to_data_hash['checksum']['value']).to eq(metadata.checksum)
    end

    describe "when a source and content_uri are set" do
      before do
        metadata.source = '/foo'
        metadata.content_uri = 'puppet:///foo'
      end

      it "the data should include the path, relative_path, links, owner, group, mode, checksum, type, destination, source, and content_uri" do
        expect(metadata.to_data_hash.keys.sort).to eq(%w{ path relative_path links owner group mode checksum type destination source content_uri }.sort)
      end

      it "should pass the source in the hash verbatim" do
        expect(metadata.to_data_hash['source']).to eq(metadata.source)
      end

      it "should pass the content_uri in the hash verbatim" do
        expect(metadata.to_data_hash['content_uri']).to eq(metadata.content_uri)
      end
    end

    describe "when assigning a content_uri" do
      it "should fail if uri is invalid" do
        expect { metadata.content_uri = '://' }.to raise_error ArgumentError, /Could not understand URI :\/\//
      end

      it "should accept characters that require percent-encoding" do
        uri = 'puppet:///modules/foo/files/ %:?#[]@!$&\'()*+,;='
        metadata.content_uri = uri
        expect(metadata.content_uri).to eq(uri)
      end

      it "should accept UTF-8 characters" do
        # different UTF-8 widths
        # 1-byte A
        # 2-byte ۿ - http://www.fileformat.info/info/unicode/char/06ff/index.htm - 0xDB 0xBF / 219 191
        # 3-byte ᚠ - http://www.fileformat.info/info/unicode/char/16A0/index.htm - 0xE1 0x9A 0xA0 / 225 154 160
        # 4-byte <U+070E> - http://www.fileformat.info/info/unicode/char/2070E/index.htm - 0xF0 0xA0 0x9C 0x8E / 240 160 156 142
        mixed_utf8 = "A\u06FF\u16A0\u{2070E}" # Aۿᚠ<U+070E>

        uri = "puppet:///modules/foo/files/ #{mixed_utf8}"
        metadata.content_uri = uri
        expect(metadata.content_uri).to eq(uri)
        expect(metadata.content_uri.encoding).to eq(Encoding::UTF_8)
      end

      it "should always set it as UTF-8" do
        uri = "puppet:///modules/foo/files/".encode(Encoding::ASCII)
        metadata.content_uri = uri
        expect(metadata.content_uri).to eq(uri)
        expect(metadata.content_uri.encoding).to eq(Encoding::UTF_8)
      end

      it "should fail if uri is opaque" do
        expect { metadata.content_uri = 'scheme:www.example.com' }.to raise_error ArgumentError, "Cannot use opaque URLs 'scheme:www.example.com'"
      end

      it "should fail if uri is not a puppet scheme" do
        expect { metadata.content_uri = 'http://www.example.com' }.to raise_error ArgumentError, "Must use URLs of type puppet as content URI"
      end
    end
  end
end

describe Puppet::FileServing::Metadata, :uses_checksums => true do
  include JSONMatchers
  include PuppetSpec::Files

  shared_examples_for "metadata collector" do
    let(:metadata) do
      data = described_class.new(path)
      data.collect
      data
    end

    describe "when collecting attributes" do
      describe "when managing files" do
        let(:path) { tmpfile('file_serving_metadata') }
        let(:time) { Time.now }

        before :each do
          FileUtils.touch(path)
        end

        describe "checksumming" do
          with_digest_algorithms do
            before :each do
              File.open(path, "wb") {|f| f.print(plaintext)}
            end

            it "should default to a checksum of the proper type with the file's current checksum" do
              expect(metadata.checksum).to eq("{#{digest_algorithm}}#{checksum}")
            end

            it "should give a #{Puppet[:digest_algorithm]} when checksum_type is set" do
              Puppet[:digest_algorithm] = nil
              metadata.checksum_type = digest_algorithm
              metadata.collect
              expect(metadata.checksum).to eq("{#{digest_algorithm}}#{checksum}")
            end
          end

          it "should give a mtime checksum when checksum_type is set" do
            metadata.checksum_type = "mtime"
            expect(metadata).to receive(:mtime_file).and_return(time)
            metadata.collect
            expect(metadata.checksum).to eq("{mtime}#{time}")
          end

          it "should give a ctime checksum when checksum_type is set" do
            metadata.checksum_type = "ctime"
            expect(metadata).to receive(:ctime_file).and_return(time)
            metadata.collect
            expect(metadata.checksum).to eq("{ctime}#{time}")
          end
        end

        it "should validate against the schema" do
          expect(metadata.to_json).to validate_against('api/schemas/file_metadata.json')
        end

        describe "when a source and content_uri are set" do
          before do
            metadata.source = '/foo'
            metadata.content_uri = 'puppet:///foo'
          end

          it "should validate against the schema" do
            expect(metadata.to_json).to validate_against('api/schemas/file_metadata.json')
          end
        end
      end

      describe "when managing directories" do
        let(:path) { tmpdir('file_serving_metadata_dir') }
        let(:time) { Time.now }

        before :each do
          expect(metadata).to receive(:ctime_file).and_return(time)
        end

        it "should only use checksums of type 'ctime' for directories" do
          metadata.collect
          expect(metadata.checksum).to eq("{ctime}#{time}")
        end

        it "should only use checksums of type 'ctime' for directories even if checksum_type set" do
          metadata.checksum_type = "mtime"
          expect(metadata).not_to receive(:mtime_file)
          metadata.collect
          expect(metadata.checksum).to eq("{ctime}#{time}")
        end

        it "should validate against the schema" do
          metadata.collect
          expect(metadata.to_json).to validate_against('api/schemas/file_metadata.json')
        end
      end
    end
  end

  describe "WindowsStat", :if => Puppet::Util::Platform.windows? do
    include PuppetSpec::Files

    it "should return default owner, group and mode when the given path has an invalid DACL (such as a non-NTFS volume)" do
      invalid_error = Puppet::Util::Windows::Error.new('Invalid DACL', 1336)
      path = tmpfile('foo')
      FileUtils.touch(path)

      allow(Puppet::Util::Windows::Security).to receive(:get_owner).with(path).and_raise(invalid_error)
      allow(Puppet::Util::Windows::Security).to receive(:get_group).with(path).and_raise(invalid_error)
      allow(Puppet::Util::Windows::Security).to receive(:get_mode).with(path).and_raise(invalid_error)

      stat = Puppet::FileSystem.stat(path)

      win_stat = Puppet::FileServing::Metadata::WindowsStat.new(stat, path, :ignore)

      expect(win_stat.owner).to eq('S-1-5-32-544')
      expect(win_stat.group).to eq('S-1-0-0')
      expect(win_stat.mode).to eq(0644)
    end

    it "should still raise errors that are not the result of an 'Invalid DACL'" do
      invalid_error = ArgumentError.new('bar')
      path = tmpfile('bar')
      FileUtils.touch(path)

      allow(Puppet::Util::Windows::Security).to receive(:get_owner).with(path).and_raise(invalid_error)
      allow(Puppet::Util::Windows::Security).to receive(:get_group).with(path).and_raise(invalid_error)
      allow(Puppet::Util::Windows::Security).to receive(:get_mode).with(path).and_raise(invalid_error)

      stat = Puppet::FileSystem.stat(path)

      expect { Puppet::FileServing::Metadata::WindowsStat.new(stat, path, :use) }.to raise_error("Unsupported Windows source permissions option use")
    end
  end

  shared_examples_for "metadata collector symlinks" do

    let(:metadata) do
      data = described_class.new(path)
      data.collect
      data
    end

    describe "when collecting attributes" do
      describe "when managing links" do
        # 'path' is a link that points to 'target'
        let(:path) { tmpfile('file_serving_metadata_link') }
        let(:target) { tmpfile('file_serving_metadata_target') }
        let(:fmode) { Puppet::FileSystem.lstat(path).mode & 0777 }

        before :each do
          File.open(target, "wb") {|f| f.print('some content')}
          set_mode(0644, target)

          Puppet::FileSystem.symlink(target, path)
        end

        it "should read links instead of returning their checksums" do
          expect(metadata.destination).to eq(target)
        end

        it "should validate against the schema" do
          expect(metadata.to_json).to validate_against('api/schemas/file_metadata.json')
        end
      end
    end

    describe Puppet::FileServing::Metadata, " when finding the file to use for setting attributes" do
      let(:path) { tmpfile('file_serving_metadata_find_file') }

      before :each do
        File.open(path, "wb") {|f| f.print('some content')}
        set_mode(0755, path)
      end

      it "should accept a base path to which the file should be relative" do
        dir = tmpdir('metadata_dir')
        metadata = described_class.new(dir)
        metadata.relative_path = 'relative_path'

        FileUtils.touch(metadata.full_path)

        metadata.collect
      end

      it "should use the set base path if one is not provided" do
        metadata.collect
      end

      it "should raise an exception if the file does not exist" do
        File.delete(path)

        expect { metadata.collect}.to raise_error(Errno::ENOENT)
      end

      it "should validate against the schema" do
        expect(metadata.to_json).to validate_against('api/schemas/file_metadata.json')
      end
    end
  end

  describe "on POSIX systems", :if => Puppet.features.posix? do
    let(:owner) {10}
    let(:group) {20}

    before :each do
      allow_any_instance_of(File::Stat).to receive(:uid).and_return(owner)
      allow_any_instance_of(File::Stat).to receive(:gid).and_return(group)
    end

    describe "when collecting attributes when managing files" do
      let(:metadata) do
        data = described_class.new(path)
        data.collect
        data
      end

      let(:path) { tmpfile('file_serving_metadata') }

      before :each do
        FileUtils.touch(path)
      end

      it "should set the owner to the Process's current owner" do
        expect(metadata.owner).to eq(Process.euid)
      end

      it "should set the group to the Process's current group" do
        expect(metadata.group).to eq(Process.egid)
      end

      it "should set the mode to the default mode" do
        set_mode(33261, path)

        expect(metadata.mode).to eq(0644)
      end
    end

    it_should_behave_like "metadata collector"
    it_should_behave_like "metadata collector symlinks"

    def set_mode(mode, path)
      File.chmod(mode, path)
    end
  end

  describe "on Windows systems", :if => Puppet::Util::Platform.windows? do
    let(:owner) {'S-1-1-50'}
    let(:group) {'S-1-1-51'}

    before :each do
      require 'puppet/util/windows/security'
      allow(Puppet::Util::Windows::Security).to receive(:get_owner).and_return(owner)
      allow(Puppet::Util::Windows::Security).to receive(:get_group).and_return(group)
    end

    describe "when collecting attributes when managing files" do
      let(:metadata) do
        data = described_class.new(path)
        data.collect
        data
      end

      let(:path) { tmpfile('file_serving_metadata') }

      before :each do
        FileUtils.touch(path)
      end

      it "should set the owner to the Process's current owner" do
        expect(metadata.owner).to eq("S-1-5-32-544")
      end

      it "should set the group to the Process's current group" do
        expect(metadata.group).to eq("S-1-0-0")
      end

      it "should set the mode to the default mode" do
        set_mode(33261, path)

        expect(metadata.mode).to eq(0644)
      end
    end

    it_should_behave_like "metadata collector"
    it_should_behave_like "metadata collector symlinks" if Puppet.features.manages_symlinks?

    describe "if ACL metadata cannot be collected" do
      let(:path) { tmpdir('file_serving_metadata_acl') }
      let(:metadata) do
        data = described_class.new(path)
        data.collect
        data
      end
      let (:invalid_dacl_error) do
        Puppet::Util::Windows::Error.new('Invalid DACL', 1336)
      end

      it "should default owner" do
        allow(Puppet::Util::Windows::Security).to receive(:get_owner).and_return(nil)

        expect(metadata.owner).to eq('S-1-5-32-544')
      end

      it "should default group" do
        allow(Puppet::Util::Windows::Security).to receive(:get_group).and_return(nil)

        expect(metadata.group).to eq('S-1-0-0')
      end

      it "should default mode" do
        allow(Puppet::Util::Windows::Security).to receive(:get_mode).and_return(nil)

        expect(metadata.mode).to eq(0644)
      end

      describe "when the path raises an Invalid ACL error" do
        # these simulate the behavior of a symlink file whose target does not support ACLs
        it "should default owner" do
          allow(Puppet::Util::Windows::Security).to receive(:get_owner).and_raise(invalid_dacl_error)

          expect(metadata.owner).to eq('S-1-5-32-544')
        end

        it "should default group" do
          allow(Puppet::Util::Windows::Security).to receive(:get_group).and_raise(invalid_dacl_error)

          expect(metadata.group).to eq('S-1-0-0')
        end

        it "should default mode" do
          allow(Puppet::Util::Windows::Security).to receive(:get_mode).and_raise(invalid_dacl_error)

          expect(metadata.mode).to eq(0644)
        end
      end
    end

    def set_mode(mode, path)
      Puppet::Util::Windows::Security.set_mode(mode, path)
    end
  end
end

describe Puppet::FileServing::Metadata, " when pointing to a link", :if => Puppet.features.manages_symlinks?, :uses_checksums => true do
  with_digest_algorithms do
    describe "when links are managed" do
      before do
        path = "/base/path/my/file"
        @file = Puppet::FileServing::Metadata.new(path, :links => :manage)
        stat = double("stat", :uid => 1, :gid => 2, :ftype => "link", :mode => 0755)
        expect(Puppet::FileSystem).to receive(:lstat).with(path).and_return(stat)
        expect(Puppet::FileSystem).to receive(:readlink).with(path).and_return("/some/other/path")
        allow(@file).to receive("#{digest_algorithm}_file".intern).and_return(checksum) # Remove these when :managed links are no longer checksumed.

        if Puppet::Util::Platform.windows?
          win_stat = double('win_stat', :owner => 'snarf', :group => 'thundercats',
            :ftype => 'link', :mode => 0755)
          allow(Puppet::FileServing::Metadata::WindowsStat).to receive(:new).and_return(win_stat)
        end
      end

      it "should store the destination of the link in :destination if links are :manage" do
        @file.collect
        expect(@file.destination).to eq("/some/other/path")
      end

      pending "should not collect the checksum if links are :manage" do
        # We'd like this to be true, but we need to always collect the checksum because in the server/client/server round trip we lose the distintion between manage and follow.
        @file.collect
        expect(@file.checksum).to be_nil
      end

      it "should collect the checksum if links are :manage" do # see pending note above
        @file.collect
        expect(@file.checksum).to eq("{#{digest_algorithm}}#{checksum}")
      end
    end

    describe "when links are followed" do
      before do
        path = "/base/path/my/file"
        @file = Puppet::FileServing::Metadata.new(path, :links => :follow)
        stat = double("stat", :uid => 1, :gid => 2, :ftype => "file", :mode => 0755)
        expect(Puppet::FileSystem).to receive(:stat).with(path).and_return(stat)
        expect(Puppet::FileSystem).not_to receive(:readlink)

        if Puppet::Util::Platform.windows?
          win_stat = double('win_stat', :owner => 'snarf', :group => 'thundercats',
            :ftype => 'file', :mode => 0755)
          allow(Puppet::FileServing::Metadata::WindowsStat).to receive(:new).and_return(win_stat)
        end

        allow(@file).to receive("#{digest_algorithm}_file".intern).and_return(checksum)
      end

      it "should not store the destination of the link in :destination if links are :follow" do
        @file.collect
        expect(@file.destination).to be_nil
      end

      it "should collect the checksum if links are :follow" do
        @file.collect
        expect(@file.checksum).to eq("{#{digest_algorithm}}#{checksum}")
      end
    end
  end
end
