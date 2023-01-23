# frozen_string_literal: true

module Puppet; end # rubocop:disable Style/Documentation

module Puppet::ResourceApi
  # This class provides a default implementation for set(), when your resource does not benefit from batching.
  # Instead of processing changes yourself, the `create`, `update`, and `delete` functions, are called for you,
  # with proper logging already set up.
  # Note that your type needs to use `name` as its namevar, and `ensure` in the conventional way to signal presence
  # and absence of resources.
  class SimpleProvider
    def set(context, changes)
      changes.each do |name, change|
        is = if context.type.feature?('simple_get_filter')
               change.key?(:is) ? change[:is] : (get(context, [name]) || []).find { |r| r[:name] == name }
             else
               change.key?(:is) ? change[:is] : (get(context) || []).find { |r| r[:name] == name }
             end
        context.type.check_schema(is) unless change.key?(:is)

        should = change[:should]

        raise 'SimpleProvider cannot be used with a Type that is not ensurable' unless context.type.ensurable?

        is = SimpleProvider.create_absent(:name, name) if is.nil?
        should = SimpleProvider.create_absent(:name, name) if should.nil?

        name_hash = if context.type.namevars.length > 1
                      # pass a name_hash containing the values of all namevars
                      name_hash = {}
                      context.type.namevars.each do |namevar|
                        name_hash[namevar] = change[:should][namevar]
                      end
                      name_hash
                    else
                      name
                    end

        if is[:ensure].to_s == 'absent' && should[:ensure].to_s == 'present'
          context.creating(name) do
            create(context, name_hash, should)
          end
        elsif is[:ensure].to_s == 'present' && should[:ensure].to_s == 'present'
          context.updating(name) do
            update(context, name_hash, should)
          end
        elsif is[:ensure].to_s == 'present' && should[:ensure].to_s == 'absent'
          context.deleting(name) do
            delete(context, name_hash)
          end
        end
      end
    end

    def create(_context, _name, _should)
      raise "#{self.class} has not implemented `create`"
    end

    def update(_context, _name, _should)
      raise "#{self.class} has not implemented `update`"
    end

    def delete(_context, _name)
      raise "#{self.class} has not implemented `delete`"
    end

    # @api private
    def self.create_absent(namevar, title)
      result = if title.is_a? Hash
                 title.dup
               else
                 { namevar => title }
               end
      result[:ensure] = 'absent'
      result
    end
  end
end
