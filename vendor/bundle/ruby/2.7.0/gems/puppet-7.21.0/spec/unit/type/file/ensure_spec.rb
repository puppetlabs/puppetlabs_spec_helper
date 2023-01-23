require 'spec_helper'

describe Puppet::Type.type(:file).attrclass(:ensure) do
  include PuppetSpec::Files

  let(:path) { tmpfile('file_ensure') }
  let(:resource) { Puppet::Type.type(:file).new(:ensure => 'file', :path => path, :replace => true) }
  let(:property) { resource.property(:ensure) }

  it "should be a subclass of Ensure" do
    expect(described_class.superclass).to eq(Puppet::Property::Ensure)
  end

  describe "when retrieving the current state" do
    it "should return :absent if the file does not exist" do
      expect(resource).to receive(:stat).and_return(nil)

      expect(property.retrieve).to eq(:absent)
    end

    it "should return the current file type if the file exists" do
      stat = double('stat', :ftype => "directory")
      expect(resource).to receive(:stat).and_return(stat)

      expect(property.retrieve).to eq(:directory)
    end
  end

  describe "when testing whether :ensure is in sync" do
    it "should always be in sync if replace is 'false' unless the file is missing" do
      property.should = :file
      expect(resource).to receive(:replace?).and_return(false)
      expect(property.safe_insync?(:link)).to be_truthy
    end

    it "should be in sync if :ensure is set to :absent and the file does not exist" do
      property.should = :absent

      expect(property).to be_safe_insync(:absent)
    end

    it "should not be in sync if :ensure is set to :absent and the file exists" do
      property.should = :absent

      expect(property).not_to be_safe_insync(:file)
    end

    it "should be in sync if a normal file exists and :ensure is set to :present" do
      property.should = :present

      expect(property).to be_safe_insync(:file)
    end

    it "should be in sync if a directory exists and :ensure is set to :present" do
      property.should = :present

      expect(property).to be_safe_insync(:directory)
    end

    it "should be in sync if a symlink exists and :ensure is set to :present" do
      property.should = :present

      expect(property).to be_safe_insync(:link)
    end

    it "should not be in sync if :ensure is set to :file and a directory exists" do
      property.should = :file

      expect(property).not_to be_safe_insync(:directory)
    end
  end

  describe "#sync" do
    context "directory" do
      before :each do
        resource[:ensure] = :directory
      end

      it "should raise if the parent directory doesn't exist" do
        newpath = File.join(path, 'nonexistentparent', 'newdir')
        resource[:path] = newpath

        expect {
          property.sync
        }.to raise_error(Puppet::Error, /Cannot create #{newpath}; parent directory #{File.dirname(newpath)} does not exist/)
      end

      it "should accept octal mode as integer" do
        resource[:mode] = '0700'
        expect(resource).to receive(:property_fix)
        expect(Dir).to receive(:mkdir).with(path, 0700)

        property.sync
      end

      it "should accept octal mode as string" do
        resource[:mode] = "700"
        expect(resource).to receive(:property_fix)
        expect(Dir).to receive(:mkdir).with(path, 0700)

        property.sync
      end

      it "should accept octal mode as string with leading zero" do
        resource[:mode] = "0700"
        expect(resource).to receive(:property_fix)
        expect(Dir).to receive(:mkdir).with(path, 0700)

        property.sync
      end

      it "should accept symbolic mode" do
        resource[:mode] = "u=rwx,go=x"
        expect(resource).to receive(:property_fix)
        expect(Dir).to receive(:mkdir).with(path, 0711)

        property.sync
      end
    end
  end
end
