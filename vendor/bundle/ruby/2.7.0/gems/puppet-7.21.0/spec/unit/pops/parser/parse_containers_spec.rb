require 'spec_helper'
require 'puppet/pops'

# relative to this spec file (./) does not work as this file is loaded by rspec
require File.join(File.dirname(__FILE__), '/parser_rspec_helper')

describe "egrammar parsing containers" do
  include ParserRspecHelper

  context "When parsing file scope" do
    it "$a = 10 $b = 20" do
      expect(dump(parse("$a = 10 $b = 20"))).to eq([
        "(block",
        "  (= $a 10)",
        "  (= $b 20)",
        ")"
        ].join("\n"))
    end

    it "$a = 10" do
      expect(dump(parse("$a = 10"))).to eq("(= $a 10)")
    end
  end

  context "When parsing class" do
    it "class foo {}" do
      expect(dump(parse("class foo {}"))).to eq("(class foo ())")
    end

    it "class foo { class bar {} }" do
      expect(dump(parse("class foo { class bar {}}"))).to eq([
        "(class foo (block",
        "  (class foo::bar ())",
        "))"
        ].join("\n"))
    end

    it "class foo::bar {}" do
      expect(dump(parse("class foo::bar {}"))).to eq("(class foo::bar ())")
    end

    it "class foo inherits bar {}" do
      expect(dump(parse("class foo inherits bar {}"))).to eq("(class foo (inherits bar) ())")
    end

    it "class foo($a) {}" do
      expect(dump(parse("class foo($a) {}"))).to eq("(class foo (parameters a) ())")
    end

    it "class foo($a, $b) {}" do
      expect(dump(parse("class foo($a, $b) {}"))).to eq("(class foo (parameters a b) ())")
    end

    it "class foo($a, $b=10) {}" do
      expect(dump(parse("class foo($a, $b=10) {}"))).to eq("(class foo (parameters a (= b 10)) ())")
    end

    it "class foo($a, $b) inherits belgo::bar {}" do
      expect(dump(parse("class foo($a, $b) inherits belgo::bar{}"))).to eq("(class foo (inherits belgo::bar) (parameters a b) ())")
    end

    it "class foo {$a = 10 $b = 20}" do
      expect(dump(parse("class foo {$a = 10 $b = 20}"))).to eq([
        "(class foo (block",
        "  (= $a 10)",
        "  (= $b 20)",
        "))"
        ].join("\n"))
    end

    context "it should handle '3x weirdness'" do
      it "class class {} # a class named 'class'" do
        # Not as much weird as confusing that it is possible to name a class 'class'. Can have
        # a very confusing effect when resolving relative names, getting the global hardwired "Class"
        # instead of some foo::class etc.
        # This was allowed in 3.x.
        expect { parse("class class {}") }.to raise_error(/'class' keyword not allowed at this location/)
      end

      it "class default {} # a class named 'default'" do
        # The weirdness here is that a class can inherit 'default' but not declare a class called default.
        # (It will work with relative names i.e. foo::default though). The whole idea with keywords as
        # names is flawed to begin with - it generally just a very bad idea.
        expect { parse("class default {}") }.to raise_error(Puppet::ParseError)
      end

      it "class 'foo' {} # a string as class name" do
        # A common error is to put quotes around the class name, the parser should provide the error message at the right location
        # See PUP-7471
        expect { parse("class 'foo' {}") }.to raise_error(/A quoted string is not valid as a name here \(line: 1, column: 7\)/)
      end


      it "class foo::default {} # a nested name 'default'" do
        expect(dump(parse("class foo::default {}"))).to eq("(class foo::default ())")
      end

      it "class class inherits default {} # inherits default" do
        expect { parse("class class inherits default {}") }.to raise_error(/'class' keyword not allowed at this location/)
      end

      it "class foo inherits class" do
        expect { parse("class foo inherits class {}") }.to raise_error(/'class' keyword not allowed at this location/)
      end
    end

    context 'it should allow keywords as attribute names' do
      ['and', 'case', 'class', 'default', 'define', 'else', 'elsif', 'if', 'in', 'inherits', 'node', 'or',
        'undef', 'unless', 'type', 'attr', 'function', 'private', 'plan', 'apply'].each do |keyword|
        it "such as #{keyword}" do
          expect { parse("class x ($#{keyword}){} class { x: #{keyword} => 1 }") }.to_not raise_error
        end
      end
    end

  end

  context "When the parser parses define" do
    it "define foo {}" do
      expect(dump(parse("define foo {}"))).to eq("(define foo ())")
    end

    it "class foo { define bar {}}" do
      expect(dump(parse("class foo {define bar {}}"))).to eq([
        "(class foo (block",
        "  (define foo::bar ())",
        "))"
        ].join("\n"))
    end

    it "define foo { define bar {}}" do
      # This is illegal, but handled as part of validation
      expect(dump(parse("define foo { define bar {}}"))).to eq([
        "(define foo (block",
        "  (define bar ())",
        "))"
        ].join("\n"))
    end

    it "define foo::bar {}" do
      expect(dump(parse("define foo::bar {}"))).to eq("(define foo::bar ())")
    end

    it "define foo($a) {}" do
      expect(dump(parse("define foo($a) {}"))).to eq("(define foo (parameters a) ())")
    end

    it "define foo($a, $b) {}" do
      expect(dump(parse("define foo($a, $b) {}"))).to eq("(define foo (parameters a b) ())")
    end

    it "define foo($a, $b=10) {}" do
      expect(dump(parse("define foo($a, $b=10) {}"))).to eq("(define foo (parameters a (= b 10)) ())")
    end

    it "define foo {$a = 10 $b = 20}" do
      expect(dump(parse("define foo {$a = 10 $b = 20}"))).to eq([
        "(define foo (block",
        "  (= $a 10)",
        "  (= $b 20)",
        "))"
        ].join("\n"))
    end

    context "it should handle '3x weirdness'" do
      it "define class {} # a define named 'class'" do
        # This is weird because Class already exists, and instantiating this define will probably not
        # work
        expect { parse("define class {}") }.to raise_error(/'class' keyword not allowed at this location/)
      end

      it "define default {} # a define named 'default'" do
        # Check unwanted ability to define 'default'.
        # The expression below is not allowed (which is good).
        expect { parse("define default {}") }.to raise_error(Puppet::ParseError)
      end
    end

    context 'it should allow keywords as attribute names' do
      ['and', 'case', 'class', 'default', 'define', 'else', 'elsif', 'if', 'in', 'inherits', 'node', 'or',
        'undef', 'unless', 'type', 'attr', 'function', 'private', 'plan', 'apply'].each do |keyword|
        it "such as #{keyword}" do
          expect {parse("define x ($#{keyword}){} x { y: #{keyword} => 1 }")}.to_not raise_error
        end
      end
    end
  end

  context "When parsing node" do
    it "node foo {}" do
      expect(dump(parse("node foo {}"))).to eq("(node (matches 'foo') ())")
    end

    it "node foo, {} # trailing comma" do
      expect(dump(parse("node foo, {}"))).to eq("(node (matches 'foo') ())")
    end

    it "node kermit.example.com {}" do
      expect(dump(parse("node kermit.example.com {}"))).to eq("(node (matches 'kermit.example.com') ())")
    end

    it "node kermit . example . com {}" do
      expect(dump(parse("node kermit . example . com {}"))).to eq("(node (matches 'kermit.example.com') ())")
    end

    it "node foo, x::bar, default {}" do
      expect(dump(parse("node foo, x::bar, default {}"))).to eq("(node (matches 'foo' 'x::bar' :default) ())")
    end

    it "node 'foo' {}" do
      expect(dump(parse("node 'foo' {}"))).to eq("(node (matches 'foo') ())")
    end

    it "node foo inherits x::bar {}" do
      expect(dump(parse("node foo inherits x::bar {}"))).to eq("(node (matches 'foo') (parent 'x::bar') ())")
    end

    it "node foo inherits 'bar' {}" do
      expect(dump(parse("node foo inherits 'bar' {}"))).to eq("(node (matches 'foo') (parent 'bar') ())")
    end

    it "node foo inherits default {}" do
      expect(dump(parse("node foo inherits default {}"))).to eq("(node (matches 'foo') (parent :default) ())")
    end

    it "node /web.*/ {}" do
      expect(dump(parse("node /web.*/ {}"))).to eq("(node (matches /web.*/) ())")
    end

    it "node /web.*/, /do\.wop.*/, and.so.on {}" do
      expect(dump(parse("node /web.*/, /do\.wop.*/, 'and.so.on' {}"))).to eq("(node (matches /web.*/ /do\.wop.*/ 'and.so.on') ())")
    end

    it "node wat inherits /apache.*/ {}" do
      expect(dump(parse("node wat inherits /apache.*/ {}"))).to eq("(node (matches 'wat') (parent /apache.*/) ())")
    end

    it "node foo inherits bar {$a = 10 $b = 20}" do
      expect(dump(parse("node foo inherits bar {$a = 10 $b = 20}"))).to eq([
        "(node (matches 'foo') (parent 'bar') (block",
        "  (= $a 10)",
        "  (= $b 20)",
        "))"
        ].join("\n"))
    end
  end
end
