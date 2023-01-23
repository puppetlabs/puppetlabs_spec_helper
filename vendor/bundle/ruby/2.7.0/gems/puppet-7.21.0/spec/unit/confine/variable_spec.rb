require 'spec_helper'

require 'puppet/confine/variable'

describe Puppet::Confine::Variable do
  it "should be named :variable" do
    expect(Puppet::Confine::Variable.name).to eq(:variable)
  end

  it "should require a value" do
    expect { Puppet::Confine::Variable.new }.to raise_error(ArgumentError)
  end

  it "should always convert values to an array" do
    expect(Puppet::Confine::Variable.new("/some/file").values).to be_instance_of(Array)
  end

  it "should have an accessor for its name" do
    expect(Puppet::Confine::Variable.new(:bar)).to respond_to(:name)
  end

  describe "when testing values" do
    before do
      @confine = Puppet::Confine::Variable.new("foo")
      @confine.name = :myvar
    end

    it "should use settings if the variable name is a valid setting" do
      expect(Puppet.settings).to receive(:valid?).with(:myvar).and_return(true)
      expect(Puppet.settings).to receive(:value).with(:myvar).and_return("foo")
      @confine.valid?
    end

    it "should use Facter if the variable name is not a valid setting" do
      expect(Puppet.settings).to receive(:valid?).with(:myvar).and_return(false)
      expect(Facter).to receive(:value).with(:myvar).and_return("foo")
      @confine.valid?
    end

    it "should be valid if the value matches the facter value" do
      expect(@confine).to receive(:test_value).and_return("foo")

      expect(@confine).to be_valid
    end

    it "should return false if the value does not match the facter value" do
      expect(@confine).to receive(:test_value).and_return("fee")

      expect(@confine).not_to be_valid
    end

    it "should be case insensitive" do
      expect(@confine).to receive(:test_value).and_return("FOO")

      expect(@confine).to be_valid
    end

    it "should not care whether the value is a string or symbol" do
      expect(@confine).to receive(:test_value).and_return("FOO")

      expect(@confine).to be_valid
    end

    it "should produce a message that the fact value is not correct" do
      @confine = Puppet::Confine::Variable.new(%w{bar bee})
      @confine.name = "eh"
      message = @confine.message("value")
      expect(message).to be_include("facter")
      expect(message).to be_include("bar,bee")
    end

    it "should be valid if the test value matches any of the provided values" do
      @confine = Puppet::Confine::Variable.new(%w{bar bee})
      expect(@confine).to receive(:test_value).and_return("bee")
      expect(@confine).to be_valid
    end
  end

  describe "when summarizing multiple instances" do
    it "should return a hash of failing variables and their values" do
      c1 = Puppet::Confine::Variable.new("one")
      c1.name = "uno"
      expect(c1).to receive(:valid?).and_return(false)
      c2 = Puppet::Confine::Variable.new("two")
      c2.name = "dos"
      expect(c2).to receive(:valid?).and_return(true)
      c3 = Puppet::Confine::Variable.new("three")
      c3.name = "tres"
      expect(c3).to receive(:valid?).and_return(false)

      expect(Puppet::Confine::Variable.summarize([c1, c2, c3])).to eq({"uno" => %w{one}, "tres" => %w{three}})
    end

    it "should combine the values of multiple confines with the same fact" do
      c1 = Puppet::Confine::Variable.new("one")
      c1.name = "uno"
      expect(c1).to receive(:valid?).and_return(false)
      c2 = Puppet::Confine::Variable.new("two")
      c2.name = "uno"
      expect(c2).to receive(:valid?).and_return(false)

      expect(Puppet::Confine::Variable.summarize([c1, c2])).to eq({"uno" => %w{one two}})
    end
  end
end
