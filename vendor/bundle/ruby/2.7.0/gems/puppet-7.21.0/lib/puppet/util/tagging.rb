# frozen_string_literal: true
require_relative '../../puppet/util/tag_set'

module Puppet::Util::Tagging
  ValidTagRegex = /\A[[:alnum:]_][[:alnum:]_:.-]*\Z/u

  # Add a tag to the current tag set.
  # When a tag set is used for a scope, these tags will be added to all of
  # the objects contained in this scope when the objects are finished.
  #
  def tag(*ary)
    @tags ||= new_tags

    ary.flatten.compact.each do |tag|
      name = tag.to_s.downcase
      # Add the tag before testing if it's valid since this means that
      # we never need to test the same valid tag twice. This speeds things
      # up since we get a lot of duplicates and rarely fail on bad tags
      if @tags.add?(name)
        # not seen before, so now we test if it is valid
        if valid_tag?(name)
          if split_qualified_tags?
          # avoid adding twice by first testing if the string contains '::'
            @tags.merge(name.split('::')) if name.include?('::')
          end
        else
          @tags.delete(name)
          fail(Puppet::ParseError, _("Invalid tag '%{name}'") % { name: name })
        end
      end
    end
  end

  # Add a name to the current tag set. Silently ignore names that does not
  # represent valid tags.
  # 
  # Use this method instead of doing this:
  #
  #  tag(name) if is_valid?(name)
  #
  # since that results in testing the same string twice
  #
  def tag_if_valid(name)
    if name.is_a?(String) && valid_tag?(name)
      name = name.downcase
      @tags ||= new_tags
      if @tags.add?(name) && name.include?('::')
        @tags.merge(name.split('::'))
      end
    end
  end

  # Answers if this resource is tagged with at least one of the given tags.
  #
  # The given tags are converted to downcased strings before the match is performed.
  #
  # @param *tags [String] splat of tags to look for
  # @return [Boolean] true if this instance is tagged with at least one of the provided tags
  #
  def tagged?(*tags)
    raw_tagged?(tags.collect {|t| t.to_s.downcase})
  end

  # Answers if this resource is tagged with at least one of the tags given in downcased string form.
  #
  # The method is a faster variant of the tagged? method that does no conversion of its
  # arguments.
  #
  # @param tag_array [Array[String]] array of tags to look for
  # @return [Boolean] true if this instance is tagged with at least one of the provided tags
  #
  def raw_tagged?(tag_array)
    my_tags = self.tags
    !tag_array.index { |t| my_tags.include?(t) }.nil?
  end

  # Only use this method when copying known tags from one Tagging instance to another
  def set_tags(tag_source)
    @tags = tag_source.tags
  end

  # Return a copy of the tag list, so someone can't ask for our tags
  # and then modify them.
  def tags
    @tags ||= new_tags
    @tags.dup
  end

  # Merge tags from a tagged instance with no attempts to split, downcase
  # or verify the tags
  def merge_tags_from(tag_source)
    @tags ||= new_tags
    tag_source.merge_into(@tags)
  end

  # Merge the tags of this instance into the provide TagSet
  def merge_into(tag_set)
    tag_set.merge(@tags) unless @tags.nil?
  end

  def tags=(tags)
    @tags = new_tags

    return if tags.nil?

    tags = tags.strip.split(/\s*,\s*/) if tags.is_a?(String)
    tag(*tags)
  end

  def valid_tag?(maybe_tag)
    begin
      tag_enc = maybe_tag.encoding
      if tag_enc == Encoding::UTF_8 || tag_enc == Encoding::ASCII
        maybe_tag =~ ValidTagRegex
      else
        maybe_tag.encode(Encoding::UTF_8) =~ ValidTagRegex
      end
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
      false
    end
  end

  private

  def split_qualified_tags?
    true
  end

  def new_tags
    Puppet::Util::TagSet.new
  end
end
