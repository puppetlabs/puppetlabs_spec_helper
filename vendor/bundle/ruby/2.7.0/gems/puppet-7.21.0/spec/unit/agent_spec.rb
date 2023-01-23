require 'spec_helper'
require 'puppet/agent'
require 'puppet/configurer'

class AgentTestClient
  def initialize(transaction_uuid = nil, job_id = nil)
  end

  def run(client_args)
    # no-op
  end

  def stop
    # no-op
  end
end

def without_warnings
  flag = $VERBOSE
  $VERBOSE = nil
  yield
  $VERBOSE = flag
end

describe Puppet::Agent do
  before do
    @agent = Puppet::Agent.new(AgentTestClient, false)

    # make Puppet::Application safe for stubbing; restore in an :after block; silence warnings for this.
    without_warnings { Puppet::Application = Class.new(Puppet::Application) }
    allow(Puppet::Application).to receive(:clear?).and_return(true)
    Puppet::Application.class_eval do
      class << self
        def controlled_run(&block)
          block.call
        end
      end
    end

    ssl_context = Puppet::SSL::SSLContext.new
    machine = instance_double("Puppet::SSL::StateMachine", ensure_client_certificate: ssl_context)
    allow(Puppet::SSL::StateMachine).to receive(:new).and_return(machine)
  end

  after do
    # restore Puppet::Application from stub-safe subclass, and silence warnings
    without_warnings { Puppet::Application = Puppet::Application.superclass }
  end

  it "should set its client class at initialization" do
    expect(Puppet::Agent.new("foo", false).client_class).to eq("foo")
  end

  it "should include the Locker module" do
    expect(Puppet::Agent.ancestors).to be_include(Puppet::Agent::Locker)
  end

  it "should create an instance of its client class and run it when asked to run" do
    client = double('client')
    allow(AgentTestClient).to receive(:new).with(nil, nil).and_return(client)

    allow(@agent).to receive(:disabled?).and_return(false)
    expect(client).to receive(:run)
    @agent.run
  end

  it "should initialize the client's transaction_uuid if passed as a client_option" do
    client = double('client')
    transaction_uuid = 'foo'
    expect(AgentTestClient).to receive(:new).with(transaction_uuid, nil).and_return(client)

    expect(client).to receive(:run)

    allow(@agent).to receive(:disabled?).and_return(false)
    @agent.run(:transaction_uuid => transaction_uuid)
  end

  it "should initialize the client's job_id if passed as a client_option" do
    client = double('client')
    job_id = '289'
    expect(AgentTestClient).to receive(:new).with(anything, job_id).and_return(client)

    expect(client).to receive(:run)

    allow(@agent).to receive(:disabled?).and_return(false)
    @agent.run(:job_id => job_id)
  end

  it "should be considered running if the lock file is locked" do
    lockfile = double('lockfile')

    expect(@agent).to receive(:lockfile).and_return(lockfile)
    expect(lockfile).to receive(:locked?).and_return(true)

    expect(@agent).to be_running
  end

  describe "when being run" do
    before do
      allow(@agent).to receive(:disabled?).and_return(false)
    end

    it "should splay" do
      Puppet[:splay] = true

      expect(@agent).to receive(:splay)

      @agent.run
    end

    it "should do nothing if disabled" do
      expect(@agent).to receive(:disabled?).and_return(true)
      expect(AgentTestClient).not_to receive(:new)
      @agent.run
    end

    it "(#11057) should notify the user about why a run is skipped" do
      allow(Puppet::Application).to receive(:controlled_run).and_return(false)
      allow(Puppet::Application).to receive(:run_status).and_return('MOCK_RUN_STATUS')
      # This is the actual test that we inform the user why the run is skipped.
      # We assume this information is contained in
      # Puppet::Application.run_status
      expect(Puppet).to receive(:notice).with(/MOCK_RUN_STATUS/)
      @agent.run
    end

    it "should display an informative message if the agent is administratively disabled" do
      expect(@agent).to receive(:disabled?).and_return(true)
      expect(@agent).to receive(:disable_message).and_return("foo")
      expect(Puppet).to receive(:notice).with(/Skipping run of .*; administratively disabled.*\(Reason: 'foo'\)/)
      @agent.run
    end

    it "should use Puppet::Application.controlled_run to manage process state behavior" do
      expect(Puppet::Application).to receive(:controlled_run).ordered.and_yield
      expect(AgentTestClient).to receive(:new).ordered.once
      @agent.run
    end

    it "should not fail if a client class instance cannot be created" do
      expect(AgentTestClient).to receive(:new).and_raise("eh")
      expect(Puppet).to receive(:log_exception)
      @agent.run
    end

    it "should not fail if there is an exception while running its client" do
      client = AgentTestClient.new
      expect(AgentTestClient).to receive(:new).and_return(client)
      expect(client).to receive(:run).and_raise("eh")
      expect(Puppet).to receive(:log_exception)
      @agent.run
    end

    it "should use a filesystem lock to restrict multiple processes running the agent" do
      client = AgentTestClient.new
      expect(AgentTestClient).to receive(:new).and_return(client)

      expect(@agent).to receive(:lock)

      expect(client).not_to receive(:run) # if it doesn't run, then we know our yield is what triggers it
      @agent.run
    end

    it "should make its client instance available while running" do
      client = AgentTestClient.new
      expect(AgentTestClient).to receive(:new).and_return(client)

      expect(client).to receive(:run) { expect(@agent.client).to equal(client); nil }
      @agent.run
    end

    it "should run the client instance with any arguments passed to it" do
      client = AgentTestClient.new
      expect(AgentTestClient).to receive(:new).and_return(client)

      expect(client).to receive(:run).with({:pluginsync => true, :other => :options})
      @agent.run(:other => :options)
    end

    it "should return the agent result" do
      client = AgentTestClient.new
      expect(AgentTestClient).to receive(:new).and_return(client)

      expect(@agent).to receive(:lock).and_return(:result)
      expect(@agent.run).to eq(:result)
    end

    it "should check if it's disabled after splaying and log a message" do
      Puppet[:splay] = true
      Puppet[:splaylimit] = '5s'
      Puppet[:onetime] = true

      expect(@agent).to receive(:disabled?).and_return(false, true)

      allow(Puppet).to receive(:notice).and_call_original
      expect(Puppet).to receive(:notice).with(/Skipping run of .*; administratively disabled.*/)
      @agent.run
    end

    it "should check if it's disabled after acquiring the lock and log a message" do
      expect(@agent).to receive(:disabled?).and_return(false, true)

      allow(Puppet).to receive(:notice).and_call_original
      expect(Puppet).to receive(:notice).with(/Skipping run of .*; administratively disabled.*/)
      @agent.run
    end

    describe "and a puppet agent is already running" do
      before(:each) do
        allow_any_instance_of(Object).to receive(:sleep)
        lockfile = double('lockfile')
        expect(@agent).to receive(:lockfile).and_return(lockfile).at_least(:once)
        # so the lock method raises Puppet::LockError
        allow(lockfile).to receive(:lock).and_return(false)
      end

      it "should notify that a run is already in progress" do
        client = AgentTestClient.new
        expect(AgentTestClient).to receive(:new).and_return(client)
        expect(Puppet).to receive(:notice).with(/Run of .* already in progress; skipping .* exists/)
        @agent.run
      end

      it "should inform that a run is already in progress and try to run every X seconds if waitforlock is used" do
        # so the locked file exists
        allow(File).to receive(:file?).and_return(true)
        # so we don't have to wait again for the run to exit (default maxwaitforcert is 60)
        # first 0 is to get the time, second 0 is to inform user, then 1000 so the time expires
        allow(Time).to receive(:now).and_return(0, 0, 1000)
        allow(Puppet).to receive(:info)
        client = AgentTestClient.new
        expect(AgentTestClient).to receive(:new).and_return(client)

        Puppet[:waitforlock] = 1
        Puppet[:maxwaitforlock] = 2
        expect(Puppet).to receive(:info).with(/Another puppet instance is already running; --waitforlock flag used, waiting for running instance to finish./)
        expect(Puppet).to receive(:info).with(/Will try again in #{Puppet[:waitforlock]} seconds./)
        @agent.run
      end

      it "should notify that the run is exiting if waitforlock is used and maxwaitforlock is exceeded" do
        # so we don't have to wait again for the run to exit (default maxwaitforcert is 60)
        # first 0 is to get the time, then 1000 so that the time expires
        allow(Time).to receive(:now).and_return(0, 1000)
        client = AgentTestClient.new
        expect(AgentTestClient).to receive(:new).and_return(client)

        Puppet[:waitforlock] = 1
        expect(Puppet).to receive(:notice).with(/Exiting now because the maxwaitforlock timeout has been exceeded./)
        @agent.run
      end
    end

    describe "when should_fork is true", :if => Puppet.features.posix? && RUBY_PLATFORM != 'java' do
      before do
        @agent = Puppet::Agent.new(AgentTestClient, true)

        # So we don't actually try to hit the filesystem.
        allow(@agent).to receive(:lock).and_yield
      end

      it "should run the agent in a forked process" do
        client = AgentTestClient.new
        expect(AgentTestClient).to receive(:new).and_return(client)

        expect(client).to receive(:run).and_return(0)

        expect(Kernel).to receive(:fork).and_yield
        expect { @agent.run }.to exit_with(0)
      end

      it "should exit child process if child exit" do
        client = AgentTestClient.new
        expect(AgentTestClient).to receive(:new).and_return(client)

        expect(client).to receive(:run).and_raise(SystemExit.new(-1))

        expect(Kernel).to receive(:fork).and_yield
        expect { @agent.run }.to exit_with(-1)
      end

      it 'should exit with 1 if an exception is raised' do
        client = AgentTestClient.new
        expect(AgentTestClient).to receive(:new).and_return(client)

        expect(client).to receive(:run).and_raise(StandardError)

        expect(Kernel).to receive(:fork).and_yield
        expect { @agent.run }.to exit_with(1)
      end

      it 'should exit with 254 if NoMemoryError exception is raised' do
        client = AgentTestClient.new
        expect(AgentTestClient).to receive(:new).and_return(client)

        expect(client).to receive(:run).and_raise(NoMemoryError)

        expect(Kernel).to receive(:fork).and_yield
        expect { @agent.run }.to exit_with(254)
      end

      it "should return the block exit code as the child exit code" do
        expect(Kernel).to receive(:fork).and_yield
        expect {
          @agent.run_in_fork {
            777
          }
        }.to exit_with(777)
      end

      it "should return `1` exit code if the block returns `nil`" do
        expect(Kernel).to receive(:fork).and_yield
        expect {
          @agent.run_in_fork {
            nil
          }
        }.to exit_with(1)
      end

      it "should return `1` exit code if the block returns `false`" do
        expect(Kernel).to receive(:fork).and_yield
        expect {
          @agent.run_in_fork {
            false
          }
        }.to exit_with(1)
      end
    end

    describe "on Windows", :if => Puppet::Util::Platform.windows? do
      it "should never fork" do
        agent = Puppet::Agent.new(AgentTestClient, true)
        expect(agent.should_fork).to be_falsey
      end
    end

    describe 'when runtimeout is set' do
      before(:each) do
        Puppet[:runtimeout] = 1
      end

      it 'times out when a run exceeds the set limit' do
        client = AgentTestClient.new
        client.instance_eval do
          # Stub methods used to set test expectations.
          def processing; end
          def handling; end

          def run(client_options = {})
            # Simulate a hanging agent operation that also traps errors.
            begin
              ::Kernel.sleep(5)
              processing()
            rescue
              handling()
            end
          end
        end

        expect(AgentTestClient).to receive(:new).and_return(client)

        expect(client).not_to receive(:processing)
        expect(client).not_to receive(:handling)
        expect(Puppet).to receive(:log_exception).with(be_an_instance_of(Puppet::Agent::RunTimeoutError), anything)

        expect(@agent.run).to eq(nil)
      end
    end
  end

  describe "when checking execution state" do
    describe 'with regular run status' do
      before :each do
        allow(Puppet::Application).to receive(:restart_requested?).and_return(false)
        allow(Puppet::Application).to receive(:stop_requested?).and_return(false)
        allow(Puppet::Application).to receive(:interrupted?).and_return(false)
        allow(Puppet::Application).to receive(:clear?).and_return(true)
      end

      it 'should be false for :stopping?' do
        expect(@agent.stopping?).to be_falsey
      end

      it 'should be false for :needing_restart?' do
        expect(@agent.needing_restart?).to be_falsey
      end
    end

    describe 'with a stop requested' do
      before :each do
        allow(Puppet::Application).to receive(:clear?).and_return(false)
        allow(Puppet::Application).to receive(:restart_requested?).and_return(false)
        allow(Puppet::Application).to receive(:stop_requested?).and_return(true)
        allow(Puppet::Application).to receive(:interrupted?).and_return(true)
      end

      it 'should be true for :stopping?' do
        expect(@agent.stopping?).to be_truthy
      end

      it 'should be false for :needing_restart?' do
        expect(@agent.needing_restart?).to be_falsey
      end
    end

    describe 'with a restart requested' do
      before :each do
        allow(Puppet::Application).to receive(:clear?).and_return(false)
        allow(Puppet::Application).to receive(:restart_requested?).and_return(true)
        allow(Puppet::Application).to receive(:stop_requested?).and_return(false)
        allow(Puppet::Application).to receive(:interrupted?).and_return(true)
      end

      it 'should be false for :stopping?' do
        expect(@agent.stopping?).to be_falsey
      end

      it 'should be true for :needing_restart?' do
        expect(@agent.needing_restart?).to be_truthy
      end
    end
  end
end
