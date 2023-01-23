require 'spec_helper'

require 'puppet/property/ordered_list'

describe Puppet::Property::OrderedList do
  it "should be a subclass of List" do
    expect(described_class.superclass).to eq(Puppet::Property::List)
  end

  describe "as an instance" do
    before do
      # Wow that's a messy interface to the resource.
      described_class.initvars
      @resource = double('resource', :[]= => nil, :property => nil)
      @property = described_class.new(:resource => @resource)
    end

    describe "when adding should to current" do
      it "should add the arrays when current is an array" do
        expect(@property.add_should_with_current(["should"], ["current"])).to eq(["should", "current"])
      end

      it "should return 'should' if current is not an array" do
        expect(@property.add_should_with_current(["should"], :absent)).to eq(["should"])
      end

      it "should return only the uniq elements leading with the order of 'should'" do
        expect(@property.add_should_with_current(["this", "is", "should"], ["is", "this", "current"])).to eq(["this", "is", "should", "current"])
      end
    end

    describe "when calling should" do
      it "should return nil if @should is nil" do
        expect(@property.should).to eq(nil)
      end

      it "should return the values of @should (without sorting) as a string if inclusive" do
        @property.should = ["foo", "bar"]
        expect(@property).to receive(:inclusive?).and_return(true)
        expect(@property.should).to eq("foo,bar")
      end

      it "should return the uniq values of @should + retrieve as a string if !inclusive with the @ values leading" do
        @property.should = ["foo", "bar"]
        expect(@property).to receive(:inclusive?).and_return(false)
        expect(@property).to receive(:retrieve).and_return(["foo","baz"])
        expect(@property.should).to eq("foo,bar,baz")
      end
    end

    describe "when calling dearrayify" do
      it "should join the array with the delimiter" do
        array = double("array")
        expect(array).to receive(:join).with(@property.delimiter)
        @property.dearrayify(array)
      end
    end
  end
end
