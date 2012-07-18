#! /usr/bin/env ruby -S rspec

require 'puppetlabs_spec_helper/puppet_spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_seams'

describe PuppetlabsSpec::PuppetSeams do
  describe "#parser_scope" do
    it "should return a Puppet::Parser::Scope instance" do
      subject.parser_scope.should be_a_kind_of Puppet::Parser::Scope
    end

    it "should be suitable for function testing" do
      scope = subject.parser_scope
      scope.function_split(["one;two", ";"]).should == [ 'one', 'two' ]
    end

    it "should accept a node name" do
      scope = subject.parser_scope("not_localhost")
      scope.compiler.node.name.should == "not_localhost"
    end

    it "should default to a node name of localhost" do
      scope = subject.parser_scope
      scope.compiler.node.name.should == "localhost"
    end

    it "should have a source set" do
      scope = subject.parser_scope
      scope.source.should_not be_nil
      scope.source.should_not be_false
    end
  end
end
