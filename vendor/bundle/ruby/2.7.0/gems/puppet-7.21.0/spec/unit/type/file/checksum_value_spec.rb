require 'spec_helper'

describe Puppet::Type.type(:file).attrclass(:checksum_value), :uses_checksums => true do
  include PuppetSpec::Files
  include_context 'with supported checksum types'

  let(:path) { tmpfile('foo_bar') }
  let(:source_file) { file_containing('temp_foo', 'nothing at all') }
  let(:environment) { Puppet::Node::Environment.create(:testing, []) }
  let(:catalog) { Puppet::Resource::Catalog.new(:test, environment) }
  let(:resource) { Puppet::Type.type(:file).new(:path => path, :catalog => catalog) }

  it "should be a property" do
    expect(described_class.superclass).to eq(Puppet::Property)
  end

  describe "when retrieving the current checksum_value" do
    let(:checksum_value) { described_class.new(:resource => resource) }

    it "should not compute a checksum if source is absent" do
      expect(resource).not_to receive(:stat)
      expect(checksum_value.retrieve).to be_nil
    end

    describe "when using a source" do
      before do
        resource[:source] = source_file
      end

      it "should return :absent if the target does not exist" do
        expect(resource).to receive(:stat).and_return(nil)

        expect(checksum_value.retrieve).to eq(:absent)
      end

      it "should not manage content on directories" do
        stat = double('stat', :ftype => "directory")
        expect(resource).to receive(:stat).and_return(stat)

        expect(checksum_value.retrieve).to be_nil
      end

      it "should not manage content on links" do
        stat = double('stat', :ftype => "link")
        expect(resource).to receive(:stat).and_return(stat)

        expect(checksum_value.retrieve).to be_nil
      end

      it "should always return the checksum as a string" do
        resource[:checksum] = :mtime

        stat = double('stat', :ftype => "file")
        expect(resource).to receive(:stat).and_return(stat)

        time = Time.now
        expect(resource.parameter(:checksum)).to receive(:mtime_file).with(resource[:path]).and_return(time)

        expect(checksum_value.retrieve).to eq(time.to_s)
      end
    end

    with_digest_algorithms do
      it "should return the checksum of the target if it exists and is a normal file" do
        stat = double('stat', :ftype => "file")
        expect(resource).to receive(:stat).and_return(stat)
        expect(resource.parameter(:checksum)).to receive("#{digest_algorithm}_file".intern).with(resource[:path]).and_return("mysum")
        resource[:source] = source_file

        expect(checksum_value.retrieve).to eq("mysum")
      end
    end
  end

  describe "when testing whether the checksum_value is in sync" do
    let(:checksum_value) { described_class.new(:resource => resource) }

    before do
      resource[:ensure] = :file
    end

    it "should return true if source is not specified" do
      checksum_value.should = "foo"
      expect(checksum_value).to be_safe_insync("whatever")
    end

    describe "when a source is provided" do
      before do
        resource[:source] = source_file
      end

      with_digest_algorithms do
        before(:each) do
          resource[:checksum] = digest_algorithm
        end

        it "should return true if the resource shouldn't be a regular file" do
          expect(resource).to receive(:should_be_file?).and_return(false)
          checksum_value.should = "foo"
          expect(checksum_value).to be_safe_insync("whatever")
        end

        it "should return false if the current checksum_value is :absent" do
          checksum_value.should = "foo"
          expect(checksum_value).not_to be_safe_insync(:absent)
        end

        it "should return false if the file should be a file but is not present" do
          expect(resource).to receive(:should_be_file?).and_return(true)
          checksum_value.should = "foo"

          expect(checksum_value).not_to be_safe_insync(:absent)
        end

        describe "and the file exists" do
          before do
            allow(resource).to receive(:stat).and_return(double("stat"))
            checksum_value.should = "somechecksum"
          end

          it "should return false if the current checksum_value is different from the desired checksum_value" do
            expect(checksum_value).not_to be_safe_insync("otherchecksum")
          end

          it "should return true if the current checksum_value is the same as the desired checksum_value" do
            expect(checksum_value).to be_safe_insync("somechecksum")
          end

          it "should include the diff module" do
            expect(checksum_value.respond_to?("diff")).to eq(false)
          end

          [true, false].product([true, false]).each do |cfg, param|
            describe "and Puppet[:show_diff] is #{cfg} and show_diff => #{param}" do
              before do
                Puppet[:show_diff] = cfg
                allow(resource).to receive(:show_diff?).and_return(param)
                resource[:loglevel] = "debug"
              end

              if cfg and param
                it "should display a diff" do
                  expect(checksum_value).to receive(:diff).and_return("my diff").once
                  expect(checksum_value).to receive(:debug).with("\nmy diff").once
                  expect(checksum_value).not_to be_safe_insync("otherchecksum")
                end
              else
                it "should not display a diff" do
                  expect(checksum_value).not_to receive(:diff)
                  expect(checksum_value).not_to be_safe_insync("otherchecksum")
                end
              end
            end
          end
        end
      end

      let(:saved_time) { Time.now }
      [:ctime, :mtime].each do |time_stat|
        [["older", -1, false], ["same", 0, true], ["newer", 1, true]].each do
          |compare, target_time, success|
          describe "with #{compare} target #{time_stat} compared to source" do
            before do
              resource[:checksum] = time_stat
              checksum_value.should = saved_time.to_s
            end

            it "should return #{success}" do
              if success
                expect(checksum_value).to be_safe_insync((saved_time+target_time).to_s)
              else
                expect(checksum_value).not_to be_safe_insync((saved_time+target_time).to_s)
              end
            end
          end
        end

        describe "with #{time_stat}" do
          before do
            resource[:checksum] = time_stat
          end

          it "should not be insync if trying to create it" do
            checksum_value.should = saved_time.to_s
            expect(checksum_value).not_to be_safe_insync(:absent)
          end

          it "should raise an error if checksum_value is not a checksum" do
            checksum_value.should = "some content"
            expect {
              checksum_value.safe_insync?(saved_time.to_s)
            }.to raise_error(/Resource with checksum_type #{time_stat} didn't contain a date in/)
          end

          it "should not be insync even if checksum_value is the absent symbol" do
            checksum_value.should = :absent
            expect(checksum_value).not_to be_safe_insync(:absent)
          end
        end
      end

      describe "and :replace is false" do
        before do
          allow(resource).to receive(:replace?).and_return(false)
        end

        it "should be insync if the file exists and the checksum_value is different" do
          allow(resource).to receive(:stat).and_return(double('stat'))

          expect(checksum_value).to be_safe_insync("whatever")
        end

        it "should be insync if the file exists and the checksum_value is right" do
          allow(resource).to receive(:stat).and_return(double('stat'))

          expect(checksum_value).to be_safe_insync("something")
        end

        it "should not be insync if the file does not exist" do
          checksum_value.should = "foo"
          expect(checksum_value).not_to be_safe_insync(:absent)
        end
      end
    end
  end

  describe "when testing whether the checksum_value is initialized in the resource and in sync" do
    CHECKSUM_TYPES_TO_TRY.each do |checksum_type, checksum|
      describe "sync with checksum type #{checksum_type} and the file exists" do
        before do
          @new_resource = Puppet::Type.type(:file).new :ensure => :file, :path => path, :catalog => catalog,
            :checksum_value => checksum, :checksum => checksum_type, :source => source_file
          allow(@new_resource).to receive(:stat).and_return(double('stat'))
        end

        it "should return false if the current checksum_value is different from the desired checksum_value" do
          expect(@new_resource.parameters[:checksum_value]).not_to be_safe_insync("abcdef")
        end

        it "should return true if the current checksum_value is the same as the desired checksum_value" do
          expect(@new_resource.parameters[:checksum_value]).to be_safe_insync(checksum)
        end
      end
    end
  end

  describe "when changing the checksum_value" do
    let(:checksum_value) { described_class.new(:resource => resource) }

    before do
      allow(resource).to receive(:[]).with(:path).and_return("/boo")
      allow(resource).to receive(:stat).and_return("eh")
    end

    it "should raise if source is absent" do
      expect(resource).not_to receive(:write)

      expect { checksum_value.sync }.to raise_error "checksum_value#sync should not be called without a source parameter"
    end

    describe "when using a source" do
      before do
        resource[:source] = source_file
      end

      it "should use the file's :write method to write the checksum_value" do
        expect(resource).to receive(:write).with(resource.parameter(:source))

        checksum_value.sync
      end

      it "should return :file_changed if the file already existed" do
        expect(resource).to receive(:stat).and_return("something")
        allow(resource).to receive(:write)
        expect(checksum_value.sync).to eq(:file_changed)
      end

      it "should return :file_created if the file did not exist" do
        expect(resource).to receive(:stat).and_return(nil)
        allow(resource).to receive(:write)
        expect(checksum_value.sync).to eq(:file_created)
      end
    end
  end
end
