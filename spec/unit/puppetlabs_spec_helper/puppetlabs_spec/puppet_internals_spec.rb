#! /usr/bin/env ruby -S rspec

require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

describe PuppetlabsSpec::PuppetInternals do
  describe ".scope" do
    it "should return a Puppet::Parser::Scope instance" do
      subject.scope.should be_a_kind_of Puppet::Parser::Scope
    end

    it "should be suitable for function testing" do
      scope = subject.scope
      scope.function_split(["one;two", ";"]).should == [ 'one', 'two' ]
    end

    it "should accept a compiler" do
      compiler = subject.compiler

      scope = subject.scope(:compiler => compiler)

      scope.compiler.should == compiler
    end

    it "should have a source set" do
      scope = subject.scope

      scope.source.should_not be_nil
      scope.source.should_not be_false
    end
  end

  describe ".resource" do
    it "can have a defined type" do
      subject.resource(:type => :node).type.should == :node
    end

    it "defaults to a type of hostclass" do
      subject.resource.type.should == :hostclass
    end

    it "can have a defined name" do
      subject.resource(:name => "testingrsrc").name.should == "testingrsrc"
    end

    it "defaults to a name of testing" do
      subject.resource.name.should == "testing"
    end
  end

  describe ".compiler" do
    let(:node) { subject.node }

    it "can have a defined node" do
      subject.compiler(:node => node).node.should be node
    end
  end

  describe ".node" do
    it "can have a defined name" do
      subject.node(:name => "mine").name.should == "mine"
    end

    it "can have a defined environment" do
      subject.node(:environment => "mine").environment.name.should == :mine
    end

    it "defaults to a name of testinghost" do
      subject.node.name.should == "testinghost"
    end
  end
end
