require 'etc'
require_relative '../../puppet/property/keyvalue'
require_relative '../../puppet/parameter/boolean'

module Puppet
  Type.newtype(:group) do
    @doc = "Manage groups. On most platforms this can only create groups.
      Group membership must be managed on individual users.

      On some platforms such as OS X, group membership is managed as an
      attribute of the group, not the user record. Providers must have
      the feature 'manages_members' to manage the 'members' property of
      a group record."

    feature :manages_members,
      "For directories where membership is an attribute of groups not users."

    feature :manages_aix_lam,
      "The provider can manage AIX Loadable Authentication Module (LAM) system."

    feature :system_groups,
      "The provider allows you to create system groups with lower GIDs."

    feature :manages_local_users_and_groups,
      "Allows local groups to be managed on systems that also use some other
       remote Name Switch Service (NSS) method of managing accounts."

    ensurable do
      desc "Create or remove the group."

      newvalue(:present) do
        provider.create
      end

      newvalue(:absent) do
        provider.delete
      end

      defaultto :present

    end

    newproperty(:gid) do
      desc "The group ID.  Must be specified numerically.  If no group ID is
        specified when creating a new group, then one will be chosen
        automatically according to local system standards. This will likely
        result in the same group having different GIDs on different systems,
        which is not recommended.

        On Windows, this property is read-only and will return the group's security
        identifier (SID)."

      def retrieve
        provider.gid
      end

      def sync
        if self.should == :absent
          raise Puppet::DevError, _("GID cannot be deleted")
        else
          provider.gid = self.should
        end
      end

      munge do |gid|
        case gid
        when String
          if gid =~ /^[-0-9]+$/
            gid = Integer(gid)
          else
            self.fail _("Invalid GID %{gid}") % { gid: gid }
          end
        when Symbol
          unless gid == :absent
            self.devfail "Invalid GID #{gid}"
          end
        end

        return gid
      end
    end

    newproperty(:members, :array_matching => :all, :required_features => :manages_members) do
      desc "The members of the group. For platforms or directory services where group
        membership is stored in the group objects, not the users. This parameter's
        behavior can be configured with `auth_membership`."

      def change_to_s(currentvalue, newvalue)
        newvalue = actual_should(currentvalue, newvalue)

        currentvalue = currentvalue.join(",") if currentvalue != :absent
        newvalue = newvalue.join(",")
        super(currentvalue, newvalue)
      end

      def insync?(current)
        if provider.respond_to?(:members_insync?)
          return provider.members_insync?(current, @should)
        end

        super(current)
      end

      def is_to_s(currentvalue)
        if provider.respond_to?(:members_to_s)
          currentvalue = '' if currentvalue.nil?
          currentvalue = currentvalue.is_a?(Array) ? currentvalue : currentvalue.split(',')

          return provider.members_to_s(currentvalue)
        end

        super(currentvalue)
      end

      def should_to_s(newvalue)
        is_to_s(actual_should(retrieve, newvalue))
      end

      # Calculates the actual should value given the current and
      # new values. This is only used in should_to_s and change_to_s
      # to fix the change notification issue reported in PUP-6542.
      def actual_should(currentvalue, newvalue)
        currentvalue = munge_members_value(currentvalue)
        newvalue = munge_members_value(newvalue)

        if @resource[:auth_membership]
          newvalue.uniq.sort 
        else
          (currentvalue + newvalue).uniq.sort
        end
      end

      # Useful helper to handle the possible property value types that we can
      # both pass-in and return. It munges the value into an array
      def munge_members_value(value)
        return [] if value == :absent
        return value.split(',') if value.is_a?(String)

        value
      end

      validate do |value|
        if provider.respond_to?(:member_valid?)
          return provider.member_valid?(value)
        end
      end
    end

    newparam(:auth_membership, :boolean => true, :parent => Puppet::Parameter::Boolean) do
      desc "Configures the behavior of the `members` parameter.

        * `false` (default) --- The provided list of group members is partial,
          and Puppet **ignores** any members that aren't listed there.
        * `true` --- The provided list of of group members is comprehensive, and
          Puppet **purges** any members that aren't listed there."
      defaultto false
    end

    newparam(:name) do
      desc "The group name. While naming limitations vary by operating system,
        it is advisable to restrict names to the lowest common denominator,
        which is a maximum of 8 characters beginning with a letter.

        Note that Puppet considers group names to be case-sensitive, regardless
        of the platform's own rules; be sure to always use the same case when
        referring to a given group."
      isnamevar
    end

    newparam(:allowdupe, :boolean => true, :parent => Puppet::Parameter::Boolean) do
      desc "Whether to allow duplicate GIDs."

      defaultto false
    end

    newparam(:ia_load_module, :required_features => :manages_aix_lam) do
      desc "The name of the I&A module to use to manage this group.
        This should be set to `files` if managing local groups."
    end

    newproperty(:attributes, :parent => Puppet::Property::KeyValue, :required_features => :manages_aix_lam) do
      desc "Specify group AIX attributes, as an array of `'key=value'` strings. This
        parameter's behavior can be configured with `attribute_membership`."

      self.log_only_changed_or_new_keys = true

      def membership
        :attribute_membership
      end

      def delimiter
        " "
      end
    end

    newparam(:attribute_membership) do
      desc "AIX only. Configures the behavior of the `attributes` parameter.

        * `minimum` (default) --- The provided list of attributes is partial, and Puppet
          **ignores** any attributes that aren't listed there.
        * `inclusive` --- The provided list of attributes is comprehensive, and
          Puppet **purges** any attributes that aren't listed there."

      newvalues(:inclusive, :minimum)

      defaultto :minimum
    end

    newparam(:system, :boolean => true, :parent => Puppet::Parameter::Boolean) do
      desc "Whether the group is a system group with lower GID."

      defaultto false
    end

    newparam(:forcelocal, :boolean => true,
             :required_features => :manages_local_users_and_groups,
             :parent => Puppet::Parameter::Boolean) do
      desc "Forces the management of local accounts when accounts are also
            being managed by some other Name Switch Service (NSS). For AIX, refer to the `ia_load_module` parameter.
            
            This option relies on your operating system's implementation of `luser*` commands, such as `luseradd` , `lgroupadd`, and `lusermod`. The `forcelocal` option could behave unpredictably in some circumstances. If the tools it depends on are not available, it might have no effect at all."
      defaultto false
    end

    # This method has been exposed for puppet to manage users and groups of
    # files in its settings and should not be considered available outside of
    # puppet.
    #
    # (see Puppet::Settings#service_group_available?)
    #
    # @return [Boolean] if the group exists on the system
    # @api private
    def exists?
      provider.exists?
    end
  end
end
