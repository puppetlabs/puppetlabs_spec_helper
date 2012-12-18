#!/usr/bin/env ruby
require 'puppetlabs_spec_helper/puppet_spec_helper'

# ensure we can access puppet settings outside of any example group
Puppet[:confdir]

# set modulepath from which to load custom type
Puppet[:modulepath] = File.join(File.dirname(__FILE__), '..', '..')

# construct a top-level describe block whose declared_class is a custom type in this module
describe Puppet::Type.type(:spechelper) do
  it "should load the type from the modulepath" do
    described_class.should be
  end

  it "should have a doc string" do
    described_class.doc.should == "This is the spechelper type"
  end
end
