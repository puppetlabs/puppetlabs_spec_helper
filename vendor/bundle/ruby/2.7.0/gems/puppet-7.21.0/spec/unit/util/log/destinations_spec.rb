require 'spec_helper'
require 'puppet/util/json'

require 'puppet/util/log'

describe Puppet::Util::Log.desttypes[:report] do
  before do
    @dest = Puppet::Util::Log.desttypes[:report]
  end

  it "should require a report at initialization" do
    expect(@dest.new("foo").report).to eq("foo")
  end

  it "should send new messages to the report" do
    report = double('report')
    dest = @dest.new(report)

    expect(report).to receive(:<<).with("my log")

    dest.handle "my log"
  end
end

describe Puppet::Util::Log.desttypes[:file] do
  include PuppetSpec::Files

  before do
    @class = Puppet::Util::Log.desttypes[:file]
  end

  it "should default to autoflush false" do
    expect(@class.new(tmpfile('log')).autoflush).to eq(true)
  end

  describe "when matching" do
    shared_examples_for "file destination" do
      it "should match an absolute path" do
        expect(@class.match?(abspath)).to be_truthy
      end

      it "should not match a relative path" do
        expect(@class.match?(relpath)).to be_falsey
      end
    end

    describe "on POSIX systems", :unless => Puppet::Util::Platform.windows? do
      describe "with a normal file" do
        let (:parent) { Pathname.new('/tmp') }
        let (:abspath) { '/tmp/log' }
        let (:relpath) { 'log' }

        it_behaves_like "file destination"
      end

      describe "with a JSON file" do
        let (:abspath) { '/tmp/log.json' }
        let (:relpath) { 'log.json' }

        it_behaves_like "file destination"

        it "should log messages as JSON" do
          msg = Puppet::Util::Log.new(:level => :info, :message => "don't panic")
          dest = @class.new(abspath)
          dest.handle(msg)
          expect(JSON.parse(File.read(abspath) + ']')).to include(a_hash_including({"message" => "don't panic"}))
        end
      end

      describe "with a JSON lines file" do
        let (:abspath) { '/tmp/log.jsonl' }
        let (:relpath) { 'log.jsonl' }

        it_behaves_like "file destination"

        it "should log messages as JSON lines" do
          msg1 = Puppet::Util::Log.new(:level => :info, :message => "don't panic")
          msg2 = Puppet::Util::Log.new(:level => :err, :message => "panic!")
          dest = @class.new(abspath)
          dest.handle(msg1)
          dest.handle(msg2)
          lines = IO.readlines(abspath)
          expect(JSON.parse(lines[-2])).to include("level" => "info", "message" => "don't panic")
          expect(JSON.parse(lines[-1])).to include("level" => "err", "message" => "panic!")
        end
      end
    end

    describe "on Windows systems", :if => Puppet::Util::Platform.windows? do
      let (:abspath) { 'C:\\temp\\log.txt' }
      let (:relpath) { 'log.txt' }

      it_behaves_like "file destination"
    end
  end
end

describe Puppet::Util::Log.desttypes[:syslog] do
  let (:klass) { Puppet::Util::Log.desttypes[:syslog] }

  # these tests can only be run when syslog is present, because
  # we can't stub the top-level Syslog module
  describe "when syslog is available", :if => Puppet.features.syslog? do
    before :each do
      allow(Syslog).to receive(:opened?).and_return(false)
      allow(Syslog).to receive(:const_get).and_return("LOG_KERN", 0)
      allow(Syslog).to receive(:open)
    end

    it "should open syslog" do
      expect(Syslog).to receive(:open)

      klass.new
    end

    it "should close syslog" do
      expect(Syslog).to receive(:close)

      dest = klass.new
      dest.close
    end

    it "should send messages to syslog" do
      syslog = double('syslog')
      expect(syslog).to receive(:info).with("don't panic")
      allow(Syslog).to receive(:open).and_return(syslog)

      msg = Puppet::Util::Log.new(:level => :info, :message => "don't panic")
      dest = klass.new
      dest.handle(msg)
    end
  end

  describe "when syslog is unavailable" do
    it "should not be a suitable log destination" do
      allow(Puppet.features).to receive(:syslog?).and_return(false)

      expect(klass.suitable?(:syslog)).to be_falsey
    end
  end
end

describe Puppet::Util::Log.desttypes[:logstash_event] do
  describe "when using structured log format with logstash_event schema" do
    before :each do
      @msg = Puppet::Util::Log.new(:level => :info, :message => "So long, and thanks for all the fish.", :source => "a dolphin")
    end

    it "format should fix the hash to have the correct structure" do
      dest = described_class.new
      result = dest.format(@msg)
      expect(result["version"]).to eq(1)
      expect(result["level"]).to   eq('info')
      expect(result["message"]).to eq("So long, and thanks for all the fish.")
      expect(result["source"]).to  eq("a dolphin")
      # timestamp should be within 10 seconds
      expect(Time.parse(result["@timestamp"])).to be >= ( Time.now - 10 )
    end

    it "format returns a structure that can be converted to json" do
      dest = described_class.new
      hash = dest.format(@msg)
      Puppet::Util::Json.load(hash.to_json)
    end

    it "handle should send the output to stdout" do
      expect($stdout).to receive(:puts).once
      dest = described_class.new
      dest.handle(@msg)
    end
  end
end

describe Puppet::Util::Log.desttypes[:console] do
  let (:klass) { Puppet::Util::Log.desttypes[:console] }

  it "should support color output" do
    Puppet[:color] = true
    expect(subject.colorize(:red, 'version')).to eq("\e[0;31mversion\e[0m")
  end

  it "should withhold color output when not appropriate" do
    Puppet[:color] = false
    expect(subject.colorize(:red, 'version')).to eq("version")
  end

  it "should handle multiple overlapping colors in a stack-like way" do
    Puppet[:color] = true
    vstring = subject.colorize(:red, 'version')
    expect(subject.colorize(:green, "(#{vstring})")).to eq("\e[0;32m(\e[0;31mversion\e[0;32m)\e[0m")
  end

  it "should handle resets in a stack-like way" do
    Puppet[:color] = true
    vstring = subject.colorize(:reset, 'version')
    expect(subject.colorize(:green, "(#{vstring})")).to eq("\e[0;32m(\e[mversion\e[0;32m)\e[0m")
  end

  it "should include the log message's source/context in the output when available" do
    Puppet[:color] = false
    expect($stdout).to receive(:puts).with("Info: a hitchhiker: don't panic")

    msg = Puppet::Util::Log.new(:level => :info, :message => "don't panic", :source => "a hitchhiker")
    dest = klass.new
    dest.handle(msg)
  end
end


describe ":eventlog", :if => Puppet::Util::Platform.windows? do
  let(:klass) { Puppet::Util::Log.desttypes[:eventlog] }

  def expects_message_with_type(klass, level, eventlog_type, eventlog_id)
    eventlog = double('eventlog')
    expect(eventlog).to receive(:report_event).with(hash_including(:event_type => eventlog_type, :event_id => eventlog_id, :data => "a hitchhiker: don't panic"))
    allow(Puppet::Util::Windows::EventLog).to receive(:open).and_return(eventlog)

    msg = Puppet::Util::Log.new(:level => level, :message => "don't panic", :source => "a hitchhiker")
    dest = klass.new
    dest.handle(msg)
  end

  it "supports the eventlog feature" do
    expect(Puppet.features.eventlog?).to be_truthy
  end

  it "should truncate extremely long log messages" do
    long_msg = "x" * 32000
    expected_truncated_msg = "#{'x' * 31785}...Message exceeds character length limit, truncating."
    expected_data = "a vogon ship: " + expected_truncated_msg

    eventlog = double('eventlog')
    expect(eventlog).to receive(:report_event).with(hash_including(:event_type => 2, :event_id => 2, :data => expected_data))
    msg = Puppet::Util::Log.new(:level => :warning, :message => long_msg, :source => "a vogon ship")
    allow(Puppet::Util::Windows::EventLog).to receive(:open).and_return(eventlog)

    dest = klass.new
    dest.handle(msg)
  end
  
  it "logs to the Puppet Application event log" do
    expect(Puppet::Util::Windows::EventLog).to receive(:open).with('Puppet').and_return(double('eventlog'))

    klass.new
  end

  it "logs :debug level as an information type event" do
    expects_message_with_type(klass, :debug, klass::EVENTLOG_INFORMATION_TYPE, 0x1)
  end

  it "logs :warning level as an warning type event" do
    expects_message_with_type(klass, :warning, klass::EVENTLOG_WARNING_TYPE, 0x2)
  end

  it "logs :err level as an error type event" do
    expects_message_with_type(klass, :err, klass::EVENTLOG_ERROR_TYPE, 0x3)
  end
end
