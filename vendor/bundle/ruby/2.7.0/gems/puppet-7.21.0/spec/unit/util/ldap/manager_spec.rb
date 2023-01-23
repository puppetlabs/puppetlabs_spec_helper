require 'spec_helper'

require 'puppet/util/ldap/manager'

describe Puppet::Util::Ldap::Manager, :if => Puppet.features.ldap? do
  before do
    @manager = Puppet::Util::Ldap::Manager.new
  end

  it "should return self when specifying objectclasses" do
    expect(@manager.manages(:one, :two)).to equal(@manager)
  end

  it "should allow specification of what objectclasses are managed" do
    expect(@manager.manages(:one, :two).objectclasses).to eq([:one, :two])
  end

  it "should return self when specifying the relative base" do
    expect(@manager.at("yay")).to equal(@manager)
  end

  it "should allow specification of the relative base" do
    expect(@manager.at("yay").location).to eq("yay")
  end

  it "should return self when specifying the attribute map" do
    expect(@manager.maps(:one => :two)).to equal(@manager)
  end

  it "should allow specification of the rdn attribute" do
    expect(@manager.named_by(:uid).rdn).to eq(:uid)
  end

  it "should allow specification of the attribute map" do
    expect(@manager.maps(:one => :two).puppet2ldap).to eq({:one => :two})
  end

  it "should have a no-op 'and' method that just returns self" do
    expect(@manager.and).to equal(@manager)
  end

  it "should allow specification of generated attributes" do
    expect(@manager.generates(:thing)).to be_instance_of(Puppet::Util::Ldap::Generator)
  end

  describe "when generating attributes" do
    before do
      @generator = double('generator', :source => "one", :name => "myparam")

      allow(Puppet::Util::Ldap::Generator).to receive(:new).with(:myparam).and_return(@generator)
    end

    it "should create a generator to do the parameter generation" do
      expect(Puppet::Util::Ldap::Generator).to receive(:new).with(:myparam).and_return(@generator)
      @manager.generates(:myparam)
    end

    it "should return the generator from the :generates method" do
      expect(@manager.generates(:myparam)).to equal(@generator)
    end

    it "should not replace already present values" do
      @manager.generates(:myparam)

      attrs = {"myparam" => "testing"}
      expect(@generator).not_to receive(:generate)

      @manager.generate attrs

      expect(attrs["myparam"]).to eq("testing")
    end

    it "should look for the parameter as a string, not a symbol" do
      @manager.generates(:myparam)
      expect(@generator).to receive(:generate).with("yay").and_return(%w{double yay})
      attrs = {"one" => "yay"}
      @manager.generate attrs

      expect(attrs["myparam"]).to eq(%w{double yay})
    end

    it "should fail if a source is specified and no source value is not defined" do
      @manager.generates(:myparam)
      expect { @manager.generate "two" => "yay" }.to raise_error(ArgumentError)
    end

    it "should use the source value to generate the new value if a source attribute is specified" do
      @manager.generates(:myparam)
      expect(@generator).to receive(:generate).with("yay").and_return(%w{double yay})
      @manager.generate "one" => "yay"
    end

    it "should not pass in any value if no source attribute is specified" do
      allow(@generator).to receive(:source).and_return(nil)
      @manager.generates(:myparam)
      expect(@generator).to receive(:generate).and_return(%w{double yay})
      @manager.generate "one" => "yay"
    end

    it "should convert any results to arrays of strings if necessary" do
      expect(@generator).to receive(:generate).and_return(:test)
      @manager.generates(:myparam)

      attrs = {"one" => "two"}
      @manager.generate(attrs)
      expect(attrs["myparam"]).to eq(["test"])
    end

    it "should add the result to the passed-in attribute hash" do
      expect(@generator).to receive(:generate).and_return(%w{test})
      @manager.generates(:myparam)

      attrs = {"one" => "two"}
      @manager.generate(attrs)
      expect(attrs["myparam"]).to eq(%w{test})
    end
  end

  it "should be considered invalid if it is missing a location" do
    @manager.manages :me
    @manager.maps :me => :you
    expect(@manager).not_to be_valid
  end

  it "should be considered invalid if it is missing an objectclass list" do
    @manager.maps :me => :you
    @manager.at "ou=yayness"
    expect(@manager).not_to be_valid
  end

  it "should be considered invalid if it is missing an attribute map" do
    @manager.manages :me
    @manager.at "ou=yayness"
    expect(@manager).not_to be_valid
  end

  it "should be considered valid if it has an attribute map, location, and objectclass list" do
    @manager.maps :me => :you
    @manager.manages :me
    @manager.at "ou=yayness"
    expect(@manager).to be_valid
  end

  it "should calculate an instance's dn using the :ldapbase setting and the relative base" do
    Puppet[:ldapbase] = "dc=testing"
    @manager.at "ou=mybase"
    expect(@manager.dn("me")).to eq("cn=me,ou=mybase,dc=testing")
  end

  it "should use the specified rdn when calculating an instance's dn" do
    Puppet[:ldapbase] = "dc=testing"
    @manager.named_by :uid
    @manager.at "ou=mybase"
    expect(@manager.dn("me")).to match(/^uid=me/)
  end

  it "should calculate its base using the :ldapbase setting and the relative base" do
    Puppet[:ldapbase] = "dc=testing"
    @manager.at "ou=mybase"
    expect(@manager.base).to eq("ou=mybase,dc=testing")
  end

  describe "when generating its search filter" do
    it "should using a single 'objectclass=<name>' filter if a single objectclass is specified" do
      @manager.manages("testing")
      expect(@manager.filter).to eq("objectclass=testing")
    end

    it "should create an LDAP AND filter if multiple objectclasses are specified" do
      @manager.manages "testing", "okay", "done"
      expect(@manager.filter).to eq("(&(objectclass=testing)(objectclass=okay)(objectclass=done))")
    end
  end

  it "should have a method for converting a Puppet attribute name to an LDAP attribute name as a string" do
    @manager.maps :puppet_attr => :ldap_attr
    expect(@manager.ldap_name(:puppet_attr)).to eq("ldap_attr")
  end

  it "should have a method for converting an LDAP attribute name to a Puppet attribute name" do
    @manager.maps :puppet_attr => :ldap_attr
    expect(@manager.puppet_name(:ldap_attr)).to eq(:puppet_attr)
  end

  it "should have a :create method for creating ldap entries" do
    expect(@manager).to respond_to(:create)
  end

  it "should have a :delete method for deleting ldap entries" do
    expect(@manager).to respond_to(:delete)
  end

  it "should have a :modify method for modifying ldap entries" do
    expect(@manager).to respond_to(:modify)
  end

  it "should have a method for finding an entry by name in ldap" do
    expect(@manager).to respond_to(:find)
  end

  describe "when converting ldap entries to hashes for providers" do
    before do
      @manager.maps :uno => :one, :dos => :two

      @result = @manager.entry2provider("dn" => ["cn=one,ou=people,dc=madstop"], "one" => ["two"], "three" => %w{four}, "objectclass" => %w{yay ness})
    end

    it "should set the name to the short portion of the dn" do
      expect(@result[:name]).to eq("one")
    end

    it "should remove the objectclasses" do
      expect(@result["objectclass"]).to be_nil
    end

    it "should remove any attributes that are not mentioned in the map" do
      expect(@result["three"]).to be_nil
    end

    it "should rename convert to symbols all attributes to their puppet names" do
      expect(@result[:uno]).to eq(%w{two})
    end

    it "should set the value of all unset puppet attributes as :absent" do
      expect(@result[:dos]).to eq(:absent)
    end
  end

  describe "when using an ldap connection" do
    before do
      @ldapconn = double('ldapconn')
      @conn = double('connection', :connection => @ldapconn, :start => nil, :close => nil)
      allow(Puppet::Util::Ldap::Connection).to receive(:new).and_return(@conn)
    end

    it "should fail unless a block is given" do
      expect { @manager.connect }.to raise_error(ArgumentError, /must pass a block/)
    end

    it "should open the connection with its server set to :ldapserver" do
      Puppet[:ldapserver] = "myserver"
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with("myserver", anything, anything).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should open the connection with its port set to the :ldapport" do
      Puppet[:ldapport] = 28
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, 28, anything).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should open the connection with no user if :ldapuser is not set" do
      Puppet[:ldapuser] = ""
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, anything, hash_excluding(:user)).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should open the connection with its user set to the :ldapuser if it is set" do
      Puppet[:ldapuser] = "mypass"
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, anything, hash_including(user: "mypass")).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should open the connection with no password if :ldappassword is not set" do
      Puppet[:ldappassword] = ""
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, anything, hash_excluding(:password)).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should open the connection with its password set to the :ldappassword if it is set" do
      Puppet[:ldappassword] = "mypass"
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, anything, hash_including(password: "mypass")).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should set ssl to :tls if ldaptls is enabled" do
      Puppet[:ldaptls] = true
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, anything, hash_including(ssl: :tls)).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should set ssl to true if ldapssl is enabled" do
      Puppet[:ldapssl] = true
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, anything, hash_including(ssl: true)).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should set ssl to false if neither ldaptls nor ldapssl is enabled" do
      Puppet[:ldapssl] = false
      expect(Puppet::Util::Ldap::Connection).to receive(:new).with(anything, anything, hash_including(ssl: false)).and_return(@conn)

      @manager.connect { |c| }
    end

    it "should open, yield, and then close the connection" do
      expect(@conn).to receive(:start)
      expect(@conn).to receive(:close)
      expect(Puppet::Util::Ldap::Connection).to receive(:new).and_return(@conn)
      expect(@ldapconn).to receive(:test)
      @manager.connect { |c| c.test }
    end

    it "should close the connection even if there's an exception in the passed block" do
      expect(@conn).to receive(:close)
      expect { @manager.connect { |c| raise ArgumentError } }.to raise_error(ArgumentError)
    end
  end

  describe "when using ldap" do
    before do
      @conn = double('connection')
      allow(@manager).to receive(:connect).and_yield(@conn)
      allow(@manager).to receive(:objectclasses).and_return([:oc1, :oc2])
      @manager.maps :one => :uno, :two => :dos, :three => :tres, :four => :quatro
    end

    describe "to create entries" do
      it "should convert the first argument to its :create method to a full dn and pass the resulting argument list to its connection" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:add).with("mydn", anything)

        @manager.create("myname", {"attr" => "myattrs"})
      end

      it "should add the objectclasses to the attributes" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:add) do |_, attrs|
          expect(attrs["objectClass"]).to include("oc1", "oc2")
        end

        @manager.create("myname", {:one => :testing})
      end

      it "should add the rdn to the attributes" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:add).with(anything, hash_including("cn" => %w{myname}))

        @manager.create("myname", {:one => :testing})
      end

      it "should add 'top' to the objectclasses if it is not listed" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:add) do |_, attrs|
          expect(attrs["objectClass"]).to include("top")
        end

        @manager.create("myname", {:one => :testing})
      end

      it "should add any generated values that are defined" do
        generator = double('generator', :source => :one, :name => "myparam")

        expect(Puppet::Util::Ldap::Generator).to receive(:new).with(:myparam).and_return(generator)

        @manager.generates(:myparam)

        allow(@manager).to receive(:dn).with("myname").and_return("mydn")

        expect(generator).to receive(:generate).with(:testing).and_return(["generated value"])
        expect(@conn).to receive(:add).with(anything, hash_including("myparam" => ["generated value"]))

        @manager.create("myname", {:one => :testing})
      end

      it "should convert any generated values to arrays of strings if necessary" do
        generator = double('generator', :source => :one, :name => "myparam")

        expect(Puppet::Util::Ldap::Generator).to receive(:new).with(:myparam).and_return(generator)

        @manager.generates(:myparam)

        allow(@manager).to receive(:dn).and_return("mydn")

        expect(generator).to receive(:generate).and_return(:generated)
        expect(@conn).to receive(:add).with(anything, hash_including("myparam" => ["generated"]))

        @manager.create("myname", {:one => :testing})
      end
    end

    describe "do delete entries" do
      it "should convert the first argument to its :delete method to a full dn and pass the resulting argument list to its connection" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:delete).with("mydn")

        @manager.delete("myname")
      end
    end

    describe "to modify entries" do
      it "should convert the first argument to its :modify method to a full dn and pass the resulting argument list to its connection" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:modify).with("mydn", :mymods)

        @manager.modify("myname", :mymods)
      end
    end

    describe "to find a single entry" do
      it "should use the dn of the provided name as the search base, a scope of 0, and 'objectclass=*' as the filter for a search2 call" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:search2).with("mydn", 0, "objectclass=*")

        @manager.find("myname")
      end

      it "should return nil if an exception is thrown because no result is found" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        expect(@conn).to receive(:search2).and_raise(LDAP::ResultError)

        expect(@manager.find("myname")).to be_nil
      end

      it "should return a converted provider hash if the result is found" do
        expect(@manager).to receive(:dn).with("myname").and_return("mydn")
        result = {"one" => "two"}
        expect(@conn).to receive(:search2).and_yield(result)

        expect(@manager).to receive(:entry2provider).with(result).and_return("myprovider")

        expect(@manager.find("myname")).to eq("myprovider")
      end
    end

    describe "to search for multiple entries" do
      before do
        allow(@manager).to receive(:filter).and_return("myfilter")
      end

      it "should use the manager's search base as the dn of the provided name as the search base" do
        expect(@manager).to receive(:base).and_return("mybase")
        expect(@conn).to receive(:search2).with("mybase", anything, anything)

        @manager.search
      end

      it "should use a scope of 1" do
        expect(@conn).to receive(:search2).with(anything, 1, anything)

        @manager.search
      end

      it "should use any specified search filter" do
        expect(@manager).not_to receive(:filter)
        expect(@conn).to receive(:search2).with(anything, anything, "boo")

        @manager.search("boo")
      end

      it "should turn its objectclass list into its search filter if one is not specified" do
        expect(@manager).to receive(:filter).and_return("yay")
        expect(@conn).to receive(:search2).with(anything, anything, "yay")

        @manager.search
      end

      it "should return nil if no result is found" do
        expect(@conn).to receive(:search2)

        expect(@manager.search).to be_nil
      end

      it "should return an array of the found results converted to provider hashes" do
        # LAK: AFAICT, it's impossible to yield multiple times in an expectation.
        one = {"dn" => "cn=one,dc=madstop,dc=com", "one" => "two"}
        expect(@conn).to receive(:search2).and_yield(one)

        expect(@manager).to receive(:entry2provider).with(one).and_return("myprov")

        expect(@manager.search).to eq(["myprov"])
      end
    end
  end

  describe "when an instance" do
    before do
      @name = "myname"
      @manager.maps :one => :uno, :two => :dos, :three => :tres, :four => :quatro
    end

    describe "is being updated" do
      it "should get created if the current attribute list is empty and the desired attribute list has :ensure == :present" do
        expect(@manager).to receive(:create)
        @manager.update(@name, {}, {:ensure => :present})
      end

      it "should get created if the current attribute list has :ensure == :absent and the desired attribute list has :ensure == :present" do
        expect(@manager).to receive(:create)
        @manager.update(@name, {:ensure => :absent}, {:ensure => :present})
      end

      it "should get deleted if the current attribute list has :ensure == :present and the desired attribute list has :ensure == :absent" do
        expect(@manager).to receive(:delete)
        @manager.update(@name, {:ensure => :present}, {:ensure => :absent})
      end

      it "should get modified if both attribute lists have :ensure == :present" do
        expect(@manager).to receive(:modify)
        @manager.update(@name, {:ensure => :present, :one => :two}, {:ensure => :present, :one => :three})
      end
    end

    describe "is being deleted" do
      it "should call the :delete method with its name and manager" do
        expect(@manager).to receive(:delete).with(@name)

        @manager.update(@name, {}, {:ensure => :absent})
      end
    end

    describe "is being created" do
      before do
        @is = {}
        @should = {:ensure => :present, :one => :yay, :two => :absent}
      end

      it "should call the :create method with its name" do
        expect(@manager).to receive(:create).with(@name, anything)
        @manager.update(@name, @is, @should)
      end

      it "should call the :create method with its property hash converted to ldap attribute names" do
        expect(@manager).to receive(:create).with(anything, hash_including("uno" => ["yay"]))
        @manager.update(@name, @is, @should)
      end

      it "should not include :ensure in the properties sent" do
        expect(@manager).to receive(:create).with(anything, hash_excluding(:ensure))
        @manager.update(@name, @is, @should)
      end

      it "should not include attributes set to :absent in the properties sent" do
        expect(@manager).to receive(:create).with(anything, hash_excluding(:dos))
        @manager.update(@name, @is, @should)
      end
    end

    describe "is being modified" do
      it "should call the :modify method with its name and an array of LDAP::Mod instances" do
        allow(LDAP::Mod).to receive(:new).and_return("whatever")

        @is = {:one => :yay}
        @should = {:one => :yay, :two => :foo}

        expect(@manager).to receive(:modify).with(@name, anything)
        @manager.update(@name, @is, @should)
      end

      it "should create the LDAP::Mod with the property name converted to the ldap name as a string" do
        @is = {:one => :yay}
        @should = {:one => :yay, :two => :foo}
        mod = double('module')
        expect(LDAP::Mod).to receive(:new).with(anything, "dos", anything).and_return(mod)

        allow(@manager).to receive(:modify)

        @manager.update(@name, @is, @should)
      end

      it "should create an LDAP::Mod instance of type LDAP_MOD_ADD for each attribute being added, with the attribute value converted to a string of arrays" do
        @is = {:one => :yay}
        @should = {:one => :yay, :two => :foo}
        mod = double('module')
        expect(LDAP::Mod).to receive(:new).with(LDAP::LDAP_MOD_ADD, "dos", ["foo"]).and_return(mod)

        allow(@manager).to receive(:modify)

        @manager.update(@name, @is, @should)
      end

      it "should create an LDAP::Mod instance of type LDAP_MOD_DELETE for each attribute being deleted" do
        @is = {:one => :yay, :two => :foo}
        @should = {:one => :yay, :two => :absent}
        mod = double('module')
        expect(LDAP::Mod).to receive(:new).with(LDAP::LDAP_MOD_DELETE, "dos", []).and_return(mod)

        allow(@manager).to receive(:modify)

        @manager.update(@name, @is, @should)
      end

      it "should create an LDAP::Mod instance of type LDAP_MOD_REPLACE for each attribute being modified, with the attribute converted to a string of arrays" do
        @is = {:one => :yay, :two => :four}
        @should = {:one => :yay, :two => :five}
        mod = double('module')
        expect(LDAP::Mod).to receive(:new).with(LDAP::LDAP_MOD_REPLACE, "dos", ["five"]).and_return(mod)

        allow(@manager).to receive(:modify)

        @manager.update(@name, @is, @should)
      end

      it "should pass all created Mod instances to the modify method" do
        @is = {:one => :yay, :two => :foo, :three => :absent}
        @should = {:one => :yay, :two => :foe, :three => :fee, :four => :fie}
        expect(LDAP::Mod).to receive(:new).exactly(3).times().and_return("mod1", "mod2", "mod3")

        expect(@manager).to receive(:modify).with(anything, contain_exactly(*%w{mod1 mod2 mod3}))

        @manager.update(@name, @is, @should)
      end
    end
  end
end
