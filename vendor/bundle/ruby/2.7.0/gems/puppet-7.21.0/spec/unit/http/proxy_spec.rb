require 'uri'
require 'spec_helper'
require 'puppet/http'

describe Puppet::HTTP::Proxy do
  before(:all) do
    ENV['http_proxy'] = nil
    ENV['HTTP_PROXY'] = nil
  end

  host, port, user, password = 'some.host', 1234, 'user1', 'pAssw0rd'

  def expects_direct_connection_to(http, www)
    expect(http.address).to eq(www.host)
    expect(http.port).to eq(www.port)

    expect(http.proxy_address).to be_nil
    expect(http.proxy_port).to be_nil
    expect(http.proxy_user).to be_nil
    expect(http.proxy_pass).to be_nil
  end

  def expects_proxy_connection_via(http, www, host, port, user, password)
    expect(http.address).to eq(www.host)
    expect(http.port).to eq(www.port)

    expect(http.proxy_address).to eq(host)
    expect(http.proxy_port).to eq(port)
    expect(http.proxy_user).to eq(user)
    expect(http.proxy_pass).to eq(password)
  end

  describe '.proxy' do
    let(:www) { URI::HTTP.build(host: 'www.example.com', port: 80) }

    it 'uses a proxy' do
      Puppet[:http_proxy_host] = host
      Puppet[:http_proxy_port] = port
      Puppet[:http_proxy_user] = user
      Puppet[:http_proxy_password] = password

      http = subject.proxy(www)
      expects_proxy_connection_via(http, www, host, port, user, password)
    end

    it 'connects directly to the server' do
      http = subject.proxy(www)
      expects_direct_connection_to(http, www)
    end

    it 'connects directly to the server when HTTP_PROXY environment variable is set, but server matches no_proxy setting' do
      Puppet[:http_proxy_host] = host
      Puppet[:http_proxy_port] = port
      Puppet[:no_proxy] = www.host

      Puppet::Util.withenv('HTTP_PROXY' => "http://#{host}:#{port}") do
        http = subject.proxy(www)
        expects_direct_connection_to(http, www)
      end
    end

    context 'when setting no_proxy' do
      before :each do
        Puppet[:http_proxy_host] = host
        Puppet[:http_proxy_port] = port
      end

      it 'connects directly to the server when HTTP_PROXY environment variable is set, but server matches no_proxy setting' do
        Puppet[:no_proxy] = www.host

        Puppet::Util.withenv('HTTP_PROXY' => "http://#{host}:#{port}") do
          http = subject.proxy(www)
          expects_direct_connection_to(http, www)
        end
      end

      it 'connects directly to the server when no_proxy matches wildcard domain' do
        Puppet[:no_proxy] = '*.example.com'

        http = subject.proxy(www)
        expects_direct_connection_to(http, www)
      end

      it 'connects directly to the server when no_proxy matches dotted domain' do
        Puppet[:no_proxy] = '.example.com'

        http = subject.proxy(www)
        expects_direct_connection_to(http, www)
      end

      it 'connects directly to the server when no_proxy matches a domain suffix like ruby does' do
        Puppet[:no_proxy] = 'example.com'

        http = subject.proxy(www)
        expects_direct_connection_to(http, www)
      end

      it 'connects directly to the server when no_proxy matches a partial suffix like ruby does' do
        Puppet[:no_proxy] = 'ample.com'

        http = subject.proxy(www)
        expects_direct_connection_to(http, www)
      end

      it 'connects directly to the server when it is a subdomain of no_proxy' do
        Puppet[:no_proxy] = '*.com'

        http = subject.proxy(www)
        expects_direct_connection_to(http, www)
      end

      it 'connects directly to the server when no_proxy is *' do
        Puppet[:no_proxy] = '*'

        http = subject.proxy(www)
        expects_direct_connection_to(http, www)
      end
    end
  end

  describe ".http_proxy_env" do
    it "should return nil if no environment variables" do
      expect(subject.http_proxy_env).to eq(nil)
    end

    it "should return a URI::HTTP object if http_proxy env variable is set" do
      Puppet::Util.withenv('HTTP_PROXY' => host) do
        expect(subject.http_proxy_env).to eq(URI.parse(host))
      end
    end

    it "should return a URI::HTTP object if HTTP_PROXY env variable is set" do
      Puppet::Util.withenv('HTTP_PROXY' => host) do
        expect(subject.http_proxy_env).to eq(URI.parse(host))
      end
    end

    it "should return a URI::HTTP object with .host and .port if URI is given" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{host}:#{port}") do
        expect(subject.http_proxy_env).to eq(URI.parse("http://#{host}:#{port}"))
      end
    end

    it "should return nil if proxy variable is malformed" do
      Puppet::Util.withenv('HTTP_PROXY' => 'this is not a valid URI') do
        expect(subject.http_proxy_env).to eq(nil)
      end
    end
  end

  describe ".http_proxy_host" do
    it "should return nil if no proxy host in config or env" do
      expect(subject.http_proxy_host).to eq(nil)
    end

    it "should return a proxy host if set in config" do
      Puppet.settings[:http_proxy_host] = host
      expect(subject.http_proxy_host).to eq(host)
    end

    it "should return nil if set to `none` in config" do
      Puppet.settings[:http_proxy_host] = 'none'
      expect(subject.http_proxy_host).to eq(nil)
    end

    it "uses environment variable before puppet settings" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{host}:#{port}") do
        Puppet.settings[:http_proxy_host] = 'not.correct'
        expect(subject.http_proxy_host).to eq(host)
      end
    end
  end

  describe ".http_proxy_port" do
    it "should return a proxy port if set in environment" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{host}:#{port}") do
        expect(subject.http_proxy_port).to eq(port)
      end
    end

    it "should return a proxy port if set in config" do
      Puppet.settings[:http_proxy_port] = port
      expect(subject.http_proxy_port).to eq(port)
    end

    it "uses environment variable before puppet settings" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{host}:#{port}") do
        Puppet.settings[:http_proxy_port] = 7456
        expect(subject.http_proxy_port).to eq(port)
      end
    end

  end

  describe ".http_proxy_user" do
    it "should return a proxy user if set in environment" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{user}:#{password}@#{host}:#{port}") do
        expect(subject.http_proxy_user).to eq(user)
      end
    end

    it "should return a proxy user if set in config" do
      Puppet.settings[:http_proxy_user] = user
      expect(subject.http_proxy_user).to eq(user)
    end

    it "should use environment variable before puppet settings" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{user}:#{password}@#{host}:#{port}") do
        Puppet.settings[:http_proxy_user] = 'clownpants'
        expect(subject.http_proxy_user).to eq(user)
      end
    end

  end

  describe ".http_proxy_password" do
    it "should return a proxy password if set in environment" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{user}:#{password}@#{host}:#{port}") do
        expect(subject.http_proxy_password).to eq(password)
      end
    end

    it "should return a proxy password if set in config" do
      Puppet.settings[:http_proxy_user] = user
      Puppet.settings[:http_proxy_password] = password
      expect(subject.http_proxy_password).to eq(password)
    end

    it "should use environment variable before puppet settings" do
      Puppet::Util.withenv('HTTP_PROXY' => "http://#{user}:#{password}@#{host}:#{port}") do
        Puppet.settings[:http_proxy_password] = 'clownpants'
        expect(subject.http_proxy_password).to eq(password)
      end
    end

  end

  describe ".no_proxy" do
    no_proxy = '127.0.0.1, localhost'
    it "should use a no_proxy list if set in environment" do
      Puppet::Util.withenv('NO_PROXY' => no_proxy) do
        expect(subject.no_proxy).to eq(no_proxy)
      end
    end

    it "should use a no_proxy list if set in config" do
      Puppet.settings[:no_proxy] = no_proxy
      expect(subject.no_proxy).to eq(no_proxy)
    end

    it "should use environment variable before puppet settings" do
      no_proxy_puppet_setting = '10.0.0.1, localhost'
      Puppet::Util.withenv('NO_PROXY' => no_proxy) do
        Puppet.settings[:no_proxy] = no_proxy_puppet_setting
        expect(subject.no_proxy).to eq(no_proxy)
      end
    end
  end

  describe ".no_proxy?" do
    no_proxy = '127.0.0.1, localhost, mydomain.com, *.otherdomain.com, oddport.com:8080, *.otheroddport.com:8080, .anotherdomain.com, .anotheroddport.com:8080'

    it "should return false if no_proxy does not exist in environment or puppet settings" do
      Puppet::Util.withenv('no_proxy' => nil) do
        dest = 'https://puppetlabs.com'
        expect(subject.no_proxy?(dest)).to be false
      end
    end

    it "should return false if the dest does not match any element in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'https://puppetlabs.com'
        expect(subject.no_proxy?(dest)).to be false
      end
    end

    it "should return true if the dest as an IP does match any element in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://127.0.0.1'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should return true if the dest as single word does match any element in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://localhost'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should return true if the dest as standard domain word does match any element in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://mydomain.com'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should return true if the dest as standard domain with port does match any element in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://oddport.com:8080'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should return false if the dest is standard domain not matching port" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://oddport.com'
        expect(subject.no_proxy?(dest)).to be false
      end
    end

    it "should return true if the dest does match any wildcarded element in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://sub.otherdomain.com'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should return true if the dest does match any wildcarded element with port in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://sub.otheroddport.com:8080'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should return true if the dest does match any domain level (no wildcard) element in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://sub.anotherdomain.com'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should return true if the dest does match any domain level (no wildcard) element with port in the no_proxy list" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = 'http://sub.anotheroddport.com:8080'
        expect(subject.no_proxy?(dest)).to be true
      end
    end

    it "should work if passed a URI object" do
      Puppet::Util.withenv('no_proxy' => no_proxy) do
        dest = URI.parse('http://sub.otheroddport.com:8080')
        expect(subject.no_proxy?(dest)).to be true
      end
    end
  end
end
