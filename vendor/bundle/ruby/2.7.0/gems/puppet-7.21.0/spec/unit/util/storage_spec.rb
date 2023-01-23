require 'spec_helper'

require 'yaml'
require 'fileutils'
require 'puppet/util/storage'

describe Puppet::Util::Storage do
  include PuppetSpec::Files

  before(:each) do
    @basepath = File.expand_path("/somepath")
  end

  describe "when caching a symbol" do
    it "should return an empty hash" do
      expect(Puppet::Util::Storage.cache(:yayness)).to eq({})
      expect(Puppet::Util::Storage.cache(:more_yayness)).to eq({})
    end

    it "should add the symbol to its internal state" do
      Puppet::Util::Storage.cache(:yayness)
      expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})
    end

    it "should not clobber existing state when caching additional objects" do
      Puppet::Util::Storage.cache(:yayness)
      expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})
      Puppet::Util::Storage.cache(:bubblyness)
      expect(Puppet::Util::Storage.state).to eq({:yayness=>{},:bubblyness=>{}})
    end
  end

  describe "when caching a Puppet::Type" do
    before(:each) do
      @file_test = Puppet::Type.type(:file).new(:name => @basepath+"/yayness", :audit => %w{checksum type})
      @exec_test = Puppet::Type.type(:exec).new(:name => @basepath+"/bin/ls /yayness")
    end

    it "should return an empty hash" do
      expect(Puppet::Util::Storage.cache(@file_test)).to eq({})
      expect(Puppet::Util::Storage.cache(@exec_test)).to eq({})
    end

    it "should add the resource ref to its internal state" do
      expect(Puppet::Util::Storage.state).to eq({})
      Puppet::Util::Storage.cache(@file_test)
      expect(Puppet::Util::Storage.state).to eq({"File[#{@basepath}/yayness]"=>{}})
      Puppet::Util::Storage.cache(@exec_test)
      expect(Puppet::Util::Storage.state).to eq({"File[#{@basepath}/yayness]"=>{}, "Exec[#{@basepath}/bin/ls /yayness]"=>{}})
    end
  end

  describe "when caching something other than a resource or symbol" do
    it "should cache by converting to a string" do
      data = Puppet::Util::Storage.cache(42)
      data[:yay] = true
      expect(Puppet::Util::Storage.cache("42")[:yay]).to be_truthy
    end
  end

  it "should clear its internal state when clear() is called" do
    Puppet::Util::Storage.cache(:yayness)
    expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})
    Puppet::Util::Storage.clear
    expect(Puppet::Util::Storage.state).to eq({})
  end

  describe "when loading from the state file" do
    before do
      allow(Puppet.settings).to receive(:use).and_return(true)
    end

    describe "when the state file/directory does not exist" do
      before(:each) do
        @path = tmpfile('storage_test')
      end

      it "should not fail to load" do
        expect(Puppet::FileSystem.exist?(@path)).to be_falsey
        Puppet[:statedir] = @path
        Puppet::Util::Storage.load
        Puppet[:statefile] = @path
        Puppet::Util::Storage.load
      end

      it "should not lose its internal state when load() is called" do
        expect(Puppet::FileSystem.exist?(@path)).to be_falsey

        Puppet::Util::Storage.cache(:yayness)
        expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})

        Puppet[:statefile] = @path
        Puppet::Util::Storage.load

        expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})
      end
    end

    describe "when the state file/directory exists" do
      before(:each) do
        @state_file = tmpfile('storage_test')
        FileUtils.touch(@state_file)
        Puppet[:statefile] = @state_file
      end

      def write_state_file(contents)
        File.open(@state_file, 'w') { |f| f.write(contents) }
      end

      it "should overwrite its internal state if load() is called" do
        # Should the state be overwritten even if Puppet[:statefile] is not valid YAML?
        Puppet::Util::Storage.cache(:yayness)
        expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})

        Puppet::Util::Storage.load

        expect(Puppet::Util::Storage.state).to eq({})
      end

      it "should restore its internal state if the state file contains valid YAML" do
        test_yaml = {'File["/yayness"]'=>{"name"=>{:a=>:b,:c=>:d}}}
        write_state_file(test_yaml.to_yaml)

        Puppet::Util::Storage.load

        expect(Puppet::Util::Storage.state).to eq(test_yaml)
      end

      it "should initialize with a clear internal state if the state file does not contain valid YAML" do
        write_state_file('{ invalid')

        Puppet::Util::Storage.load

        expect(Puppet::Util::Storage.state).to eq({})
      end

      it "should initialize with a clear internal state if the state file does not contain a hash of data" do
        write_state_file("not_a_hash")

        Puppet::Util::Storage.load

        expect(Puppet::Util::Storage.state).to eq({})
      end

      it "should raise an error if the state file does not contain valid YAML and cannot be renamed" do
        allow(File).to receive(:rename).and_call_original

        write_state_file('{ invalid')

        expect(File).to receive(:rename).with(@state_file, "#{@state_file}.bad").and_raise(SystemCallError)

        expect { Puppet::Util::Storage.load }.to raise_error(Puppet::Error, /Could not rename/)
      end

      it "should attempt to rename the state file if the file is corrupted" do
        write_state_file('{ invalid')

        expect(File).to receive(:rename).at_least(:once)

        Puppet::Util::Storage.load
      end

      it "should fail gracefully on load() if the state file is not a regular file" do
        FileUtils.rm_f(@state_file)
        Dir.mkdir(@state_file)

        Puppet::Util::Storage.load
      end

      it 'should load Time and Symbols' do
        state = {
          'File[/etc/puppetlabs/puppet]' =>
          { :checked => Time.new(2018, 8, 8, 15, 28, 25, "-07:00") }
        }
        write_state_file(YAML.dump(state))

        Puppet::Util::Storage.load

        expect(Puppet::Util::Storage.state).to eq(state.dup)
      end
    end
  end

  describe "when storing to the state file" do
    A_SMALL_AMOUNT_OF_TIME = 0.001 #Seconds

    before(:each) do
      @state_file = tmpfile('storage_test')
      @saved_statefile = Puppet[:statefile]
      Puppet[:statefile] = @state_file
    end

    it "should create the state file if it does not exist" do
      expect(Puppet::FileSystem.exist?(Puppet[:statefile])).to be_falsey
      Puppet::Util::Storage.cache(:yayness)

      Puppet::Util::Storage.store

      expect(Puppet::FileSystem.exist?(Puppet[:statefile])).to be_truthy
    end

    it "should raise an exception if the state file is not a regular file" do
      Dir.mkdir(Puppet[:statefile])
      Puppet::Util::Storage.cache(:yayness)

      expect { Puppet::Util::Storage.store }.to raise_error(Errno::EISDIR, /Is a directory/)

      Dir.rmdir(Puppet[:statefile])
    end

    it "should load() the same information that it store()s" do
      Puppet::Util::Storage.cache(:yayness)
      expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})

      Puppet::Util::Storage.store
      Puppet::Util::Storage.clear

      expect(Puppet::Util::Storage.state).to eq({})

      Puppet::Util::Storage.load

      expect(Puppet::Util::Storage.state).to eq({:yayness=>{}})
    end

    it "expires entries with a :checked older than statettl seconds ago" do
      Puppet[:statettl] = '1d'
      recent_checked = Time.now.round
      stale_checked = recent_checked - (Puppet[:statettl] + 10)
      Puppet::Util::Storage.cache(:yayness)[:checked] = recent_checked
      Puppet::Util::Storage.cache(:stale)[:checked] = stale_checked
      expect(Puppet::Util::Storage.state).to match(
        {
          :yayness => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(recent_checked)
          },
          :stale => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(stale_checked)
          }
        }
      )

      Puppet::Util::Storage.store
      Puppet::Util::Storage.clear

      expect(Puppet::Util::Storage.state).to eq({})

      Puppet::Util::Storage.load

      expect(Puppet::Util::Storage.state).to match(
        {
          :yayness => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(recent_checked)
          }
        }
      )
    end

    it "does not expire entries when statettl is 0" do
      Puppet[:statettl] = '0'
      recent_checked = Time.now.round
      older_checked = recent_checked - 10_000_000
      Puppet::Util::Storage.cache(:yayness)[:checked] = recent_checked
      Puppet::Util::Storage.cache(:older)[:checked] = older_checked
      expect(Puppet::Util::Storage.state).to match(
        {
          :yayness => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(recent_checked)
          },
          :older => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(older_checked)
          }
        }
      )

      Puppet::Util::Storage.store
      Puppet::Util::Storage.clear

      expect(Puppet::Util::Storage.state).to eq({})

      Puppet::Util::Storage.load

      expect(Puppet::Util::Storage.state).to match(
        {
          :yayness => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(recent_checked)
          },
          :older => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(older_checked)
          }
        }
      )
    end

    it "does not expire entries when statettl is 'unlimited'" do
      Puppet[:statettl] = 'unlimited'
      recent_checked = Time.now
      older_checked = Time.now - 10_000_000
      Puppet::Util::Storage.cache(:yayness)[:checked] = recent_checked
      Puppet::Util::Storage.cache(:older)[:checked] = older_checked
      expect(Puppet::Util::Storage.state).to match(
        {
          :yayness => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(recent_checked)
          },
          :older => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(older_checked)
          }
        }
      )

      Puppet::Util::Storage.store
      Puppet::Util::Storage.clear

      expect(Puppet::Util::Storage.state).to eq({})

      Puppet::Util::Storage.load

      expect(Puppet::Util::Storage.state).to match(
        {
          :yayness => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(recent_checked)
          },
          :older => {
            :checked => a_value_within(A_SMALL_AMOUNT_OF_TIME).of(older_checked)
          }
        }
      )
    end
  end
end
