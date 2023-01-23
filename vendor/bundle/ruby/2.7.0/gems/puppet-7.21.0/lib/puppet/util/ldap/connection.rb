require_relative '../../../puppet/util/ldap'

class Puppet::Util::Ldap::Connection
  attr_accessor :host, :port, :user, :password, :reset, :ssl

  attr_reader :connection

  # Return a default connection, using our default settings.
  def self.instance
    ssl = if Puppet[:ldaptls]
      :tls
        elsif Puppet[:ldapssl]
          true
        else
          false
        end

    options = {}
    options[:ssl] = ssl
    user = Puppet.settings[:ldapuser]
    if user && user != ""
      options[:user] = user
      pass = Puppet.settings[:ldappassword]
      if pass && pass != ""
        options[:password] = pass
      end
    end

    new(Puppet[:ldapserver], Puppet[:ldapport], options)
  end

  def close
    connection.unbind if connection.bound?
  end

  def initialize(host, port, user: nil, password: nil, reset: nil, ssl: nil)
    raise Puppet::Error, _("Could not set up LDAP Connection: Missing ruby/ldap libraries") unless Puppet.features.ldap?

    @host = host
    @port = port
    @user = user
    @password = password
    @reset = reset
    @ssl = ssl
  end

  # Create a per-connection unique name.
  def name
    [host, port, user, password, ssl].collect { |p| p.to_s }.join("/")
  end

  # Should we reset the connection?
  def reset?
    reset
  end

  # Start our ldap connection.
  def start
      case ssl
      when :tls
        @connection = LDAP::SSLConn.new(host, port, true)
      when true
        @connection = LDAP::SSLConn.new(host, port)
      else
        @connection = LDAP::Conn.new(host, port)
      end
      @connection.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
      @connection.set_option(LDAP::LDAP_OPT_REFERRALS, LDAP::LDAP_OPT_ON)
      @connection.simple_bind(user, password)
  rescue => detail
      raise Puppet::Error, _("Could not connect to LDAP: %{detail}") % { detail: detail }, detail.backtrace
  end
end
