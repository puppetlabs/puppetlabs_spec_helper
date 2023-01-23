require 'spec_helper'
require 'puppet/pops'

describe "Puppet::Pops::Issues" do
  include Puppet::Pops::Issues

  it "should have an issue called NAME_WITH_HYPHEN" do
    x = Puppet::Pops::Issues::NAME_WITH_HYPHEN
    expect(x.class).to eq(Puppet::Pops::Issues::Issue)
    expect(x.issue_code).to eq(:NAME_WITH_HYPHEN)
  end

  it "should should format a message that requires an argument" do
    x = Puppet::Pops::Issues::NAME_WITH_HYPHEN
    expect(x.format(:name => 'Boo-Hoo',
      :label => Puppet::Pops::Model::ModelLabelProvider.new,
      :semantic => "dummy"
      )).to eq("A String may not have a name containing a hyphen. The name 'Boo-Hoo' is not legal")
  end

  it "should should format a message that does not require an argument" do
    x = Puppet::Pops::Issues::NOT_TOP_LEVEL
    expect(x.format()).to eq("Classes, definitions, and nodes may only appear at toplevel or inside other classes")
  end

end

describe "Puppet::Pops::IssueReporter" do

  let(:acceptor) { Puppet::Pops::Validation::Acceptor.new }

  def fake_positioned(number)
    double("positioned_#{number}", :line => number, :pos => number)
  end

  def diagnostic(severity,  number, args)
    Puppet::Pops::Validation::Diagnostic.new(
      severity,
      Puppet::Pops::Issues::Issue.new(number) { "#{severity}#{number}" },
      "#{severity}file",
      fake_positioned(number),
      args)
  end

  def warning(number, args = {})
    diagnostic(:warning, number, args)
  end

  def deprecation(number, args = {})
    diagnostic(:deprecation, number, args)
  end

  def error(number, args = {})
    diagnostic(:error, number, args)
  end

  context "given warnings" do

    before(:each) do
      acceptor.accept( warning(1) )
      acceptor.accept( deprecation(1) )
    end

    it "emits warnings if told to emit them" do
      expect(Puppet::Log).to receive(:create).twice.with(hash_including(:level => :warning, :message => match(/warning1|deprecation1/)))
      Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_warnings => true })
    end

    it "does not emit warnings if not told to emit them" do
      expect(Puppet::Log).not_to receive(:create)
      Puppet::Pops::IssueReporter.assert_and_report(acceptor, {})
    end

    it "emits no warnings if :max_warnings is 0" do
      acceptor.accept( warning(2) )
      Puppet[:max_warnings] = 0
      expect(Puppet::Log).to receive(:create).once.with(hash_including(:level => :warning, :message => match(/deprecation1/)))
      Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_warnings => true })
    end

    it "emits no more than 1 warning if :max_warnings is 1" do
      acceptor.accept( warning(2) )
      acceptor.accept( warning(3) )
      Puppet[:max_warnings] = 1
      expect(Puppet::Log).to receive(:create).twice.with(hash_including(:level => :warning, :message => match(/warning1|deprecation1/)))
      Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_warnings => true })
    end

    it "does not emit more deprecations warnings than the max deprecation warnings" do
      acceptor.accept( deprecation(2) )
      Puppet[:max_deprecations] = 0
      expect(Puppet::Log).to receive(:create).once.with(hash_including(:level => :warning, :message => match(/warning1/)))
      Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_warnings => true })
    end

    it "does not emit deprecation warnings, but does emit regular warnings if disable_warnings includes deprecations" do
      Puppet[:disable_warnings] = 'deprecations'
      expect(Puppet::Log).to receive(:create).once.with(hash_including(:level => :warning, :message => match(/warning1/)))
      Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_warnings => true })
    end

    it "includes diagnostic arguments in logged entry" do
      acceptor.accept( warning(2, :n => 'a') )
      expect(Puppet::Log).to receive(:create).twice.with(hash_including(:level => :warning, :message => match(/warning1|deprecation1/)))
      expect(Puppet::Log).to receive(:create).once.with(hash_including(:level => :warning, :message => match(/warning2/), :arguments => {:n => 'a'}))
      Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_warnings => true })
    end
  end

  context "given errors" do
    it "logs nothing, but raises the given :message if :emit_errors is repressing error logging" do
      acceptor.accept( error(1) )
      expect(Puppet::Log).not_to receive(:create)
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_errors => false, :message => 'special'})
      end.to raise_error(Puppet::ParseError, 'special')
    end

    it "prefixes :message if a single error is raised" do
      acceptor.accept( error(1) )
      expect(Puppet::Log).not_to receive(:create)
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :message => 'special'})
      end.to raise_error(Puppet::ParseError, /special error1/)
    end

    it "logs nothing and raises immediately if there is only one error" do
      acceptor.accept( error(1) )
      expect(Puppet::Log).not_to receive(:create)
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { })
      end.to raise_error(Puppet::ParseError, /error1/)
    end

    it "logs nothing and raises immediately if there are multiple errors but max_errors is 0" do
      acceptor.accept( error(1) )
      acceptor.accept( error(2) )
      Puppet[:max_errors] = 0
      expect(Puppet::Log).not_to receive(:create)
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { })
      end.to raise_error(Puppet::ParseError, /error1/)
    end

    it "logs the :message if there is more than one allowed error" do
      acceptor.accept( error(1) )
      acceptor.accept( error(2) )
      expect(Puppet::Log).to receive(:create).exactly(3).times.with(hash_including(:level => :err, :message => match(/error1|error2|special/)))
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :message => 'special'})
      end.to raise_error(Puppet::ParseError, /Giving up/)
    end

    it "emits accumulated errors before raising a 'giving up' message if there are more errors than allowed" do
      acceptor.accept( error(1) )
      acceptor.accept( error(2) )
      acceptor.accept( error(3) )
      Puppet[:max_errors] = 2
      expect(Puppet::Log).to receive(:create).twice.with(hash_including(:level => :err, :message => match(/error1|error2/)))
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { })
      end.to raise_error(Puppet::ParseError, /3 errors.*Giving up/)
    end

    it "emits accumulated errors before raising a 'giving up' message if there are multiple errors but fewer than limits" do
      acceptor.accept( error(1) )
      acceptor.accept( error(2) )
      acceptor.accept( error(3) )
      Puppet[:max_errors] = 4
      expect(Puppet::Log).to receive(:create).exactly(3).times.with(hash_including(:level => :err, :message => match(/error[123]/)))
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { })
      end.to raise_error(Puppet::ParseError, /3 errors.*Giving up/)
    end

    it "emits errors regardless of disable_warnings setting" do
      acceptor.accept( error(1) )
      acceptor.accept( error(2) )
      Puppet[:disable_warnings] = 'deprecations'
      expect(Puppet::Log).to receive(:create).twice.with(hash_including(:level => :err, :message => match(/error1|error2/)))
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { })
      end.to raise_error(Puppet::ParseError, /Giving up/)
    end

    it "includes diagnostic arguments in raised error" do
      acceptor.accept( error(1, :n => 'a') )
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { })
      end.to raise_error(Puppet::ParseErrorWithIssue, /error1/) { |ex| expect(ex.arguments).to eq(:n => 'a')}
    end
  end

  context "given both" do

    it "logs warnings and errors" do
      acceptor.accept( warning(1) )
      acceptor.accept( error(1) )
      acceptor.accept( error(2) )
      acceptor.accept( error(3) )
      acceptor.accept( deprecation(1) )
      Puppet[:max_errors] = 2
      expect(Puppet::Log).to receive(:create).twice.with(hash_including(:level => :warning, :message => match(/warning1|deprecation1/)))
      expect(Puppet::Log).to receive(:create).twice.with(hash_including(:level => :err, :message => match(/error[123]/)))
      expect do
        Puppet::Pops::IssueReporter.assert_and_report(acceptor, { :emit_warnings => true })
      end.to raise_error(Puppet::ParseError, /3 errors.*2 warnings.*Giving up/)
    end
  end
end
