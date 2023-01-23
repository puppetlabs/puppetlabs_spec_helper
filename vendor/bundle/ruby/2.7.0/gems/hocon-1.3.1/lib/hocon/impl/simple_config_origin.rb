# encoding: utf-8

require 'uri'
require 'hocon/impl'
require 'hocon/impl/url'
require 'hocon/impl/origin_type'
require 'hocon/config_error'

class Hocon::Impl::SimpleConfigOrigin

  OriginType = Hocon::Impl::OriginType

  def initialize(description, line_number, end_line_number,
                 origin_type, url_or_nil, resource_or_nil, comments_or_nil)
    if !description
      raise ArgumentError, "description may not be nil"
    end

    # HACK: naming this variable with an underscore, because the upstream library
    # has both a member var and a no-arg method by the name "description", and
    # I don't think Ruby can handle that.
    @_description = description
    @line_number = line_number
    @end_line_number = end_line_number
    @origin_type = origin_type

    # TODO: Currently ruby hocon does not support URLs, and so this variable
    # is not actually a URL/URI, but a string
    @url_or_nil = url_or_nil
    @resource_or_nil = resource_or_nil
    @comments_or_nil = comments_or_nil
  end

  attr_reader :_description, :line_number, :end_line_number, :origin_type,
              :url_or_nil, :resource_or_nil, :comments_or_nil


  def self.new_simple(description)
    self.new(description, -1, -1,
             OriginType::GENERIC,
             nil, nil, nil)
  end

  def self.new_file(file_path)
    self.new(file_path, -1, -1,
             OriginType::FILE,
             file_path, nil, nil)
  end

  # NOTE: not porting `new_url` because we're not going to support URLs for now

  def self.new_resource(resource, url = nil)
    desc = nil
    if ! url.nil?
      desc = resource + " @ " + url.to_external_form
    else
      desc = resource
    end
    Hocon::Impl::SimpleConfigOrigin.new(desc, -1, -1, OriginType::RESOURCE,
                           url.nil? ? nil : url.to_external_form,
                           resource, nil)
  end

  def with_line_number(line_number)
    if (line_number == @line_number) and
        (line_number == @end_line_number)
      self
    else
      Hocon::Impl::SimpleConfigOrigin.new(
          @_description, line_number, line_number,
          @origin_type, @url_or_nil, @resource_or_nil, @comments_or_nil)
    end
  end

  def add_url(url)
    SimpleConfigOrigin.new(@_description, line_number, end_line_number, origin_type,
                           url.nil? ? nil : url.to_s, resource_or_nil,
                           comments_or_nil)
  end

  def with_comments(comments)
    if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(comments, @comments_or_nil)
      self
    else
      Hocon::Impl::SimpleConfigOrigin.new(
          @_description, @line_number, @end_line_number,
          @origin_type, @url_or_nil, @resource_or_nil, comments)
    end
  end

  def prepend_comments(comments)
    if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(comments, @comments_or_nil)
      self
    elsif @comments_or_nil.nil?
      with_comments(comments)
    else
      merged = comments + @comments_or_nil
      with_comments(merged)
    end
  end

  def append_comments(comments)
    if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(comments, @comments_or_nil)
      self
    elsif comments_or_nil.nil?
      with_comments(comments)
    else
      merged = comments_or_nil + comments
      with_comments(merged)
    end
  end

  def description
    if @line_number < 0
      _description
    elsif end_line_number == line_number
      "#{_description}: #{line_number}"
    else
      "#{_description}: #{line_number}-#{end_line_number}"
    end
  end

  def ==(other)
    if other.is_a? Hocon::Impl::SimpleConfigOrigin
      @_description == other._description &&
          @line_number == other.line_number &&
          @end_line_number == other.end_line_number &&
          @origin_type == other.origin_type &&
          Hocon::Impl::ConfigImplUtil.equals_handling_nil?(@url_or_nil, other.url_or_nil) &&
          Hocon::Impl::ConfigImplUtil.equals_handling_nil?(@resource_or_nil, other.resource_or_nil)
    else
      false
    end
  end

  def hash
    h = 41 * (41 + @_description.hash)
    h = 41 * (h + @line_number)
    h = 41 * (h + @end_line_number)
    h = 41 * (h + @origin_type.hash)

    unless @url_or_nil.nil?
      h = 41 * (h + @url_or_nil.hash)
    end

    unless @resource_or_nil.nil?
      h = 41 * (h + @resource_or_nil.hash)
    end

    h
  end

  def to_s
    "ConfigOrigin(#{_description})"
  end

  def filename
    # TODO because we don't support URLs, this function's URL handling
    # is completely pointless. It will only return _description (a string that
    # is the file path) or nil.
    # It should be cleaned up
    if origin_type == OriginType::FILE
      _description
    elsif ! url_or_nil.nil?
      url = nil
      begin
        url = Hocon::Impl::Url.new(url_or_nil)
      rescue Hocon::Impl::Url::MalformedUrlError => e
        return nil
      end

      if url.get_protocol == "file"
        url.get_file
      else
        nil
      end
    else
      nil
    end
  end

  def url
    if url_or_nil.nil?
      nil
    else
      begin
        Hocon::Impl::Url.new(url_or_nil)
      rescue Hocon::Impl::Url::MalformedUrlError => e
        nil
      end
    end
  end

  def resource
    resource_or_nil
  end

  def comments
    @comments_or_nil || []
  end

  MERGE_OF_PREFIX = "merge of "

  def self.remove_merge_of_prefix(desc)
    if desc.start_with?(MERGE_OF_PREFIX)
      desc = desc[MERGE_OF_PREFIX.length, desc.length - 1]
    end
    desc
  end

  def self.merge_two(a, b)
    merged_desc = nil
    merged_start_line = nil
    merged_end_line = nil
    merged_comments = nil

    merged_type =
        if a.origin_type == b.origin_type
          a.origin_type
        else
          Hocon::Impl::OriginType::GENERIC
        end

    # first use the "description" field which has no line numbers
    # cluttering it.
    a_desc = remove_merge_of_prefix(a._description)
    b_desc = remove_merge_of_prefix(b._description)

    if a_desc == b_desc
      merged_desc = a_desc
      if a.line_number < 0
        merged_start_line = b.line_number
      elsif b.line_number < 0
        merged_start_line = a.line_number
      else
        merged_start_line = [a.line_number, b.line_number].min
      end

      merged_end_line = [a.end_line_number, b.end_line_number].max
    else
      # this whole merge song-and-dance was intended to avoid this case
      # whenever possible, but we've lost. Now we have to lose some
      # structured information and cram into a string.
      #
      # description() method includes line numbers, so use it instead
      # of description field.
      a_full = remove_merge_of_prefix(a._description)
      b_full = remove_merge_of_prefix(b._description)

      merged_desc = "#{MERGE_OF_PREFIX}#{a_full},#{b_full}"
      merged_start_line = -1
      merged_end_line = -1
    end

    merged_url =
        if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(a.url_or_nil, b.url_or_nil)
          a.url_or_nil
        else
          nil
        end

    merged_resource =
        if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(a.resource_or_nil, b.resource_or_nil)
          a.resource_or_nil
        else
          nil
        end

    if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(a.comments_or_nil, b.comments_or_nil)
      merged_comments = a.comments_or_nil
    else
      merged_comments = []
      if a.comments_or_nil
        merged_comments.concat(a.comments_or_nil)
      end
      if b.comments_or_nil
        merged_comments.concat(b.comments_or_nil)
      end
    end

    Hocon::Impl::SimpleConfigOrigin.new(
        merged_desc, merged_start_line, merged_end_line,
        merged_type, merged_url, merged_resource, merged_comments)
  end

  def self.similarity(a, b)
    count = 0
    if a.origin_type == b.origin_type
      count += 1
    end

    if a._description == b._description
      count += 1

      # only count these if the description field (which is the file
      # or resource name) also matches.
      if a.line_number == b.line_number
        count += 1
      end

      if a.end_line_number == b.end_line_number
        count += 1
      end

      if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(a.url_or_nil, b.url_or_nil)
        count += 1
      end

      if Hocon::Impl::ConfigImplUtil.equals_handling_nil?(a.resource_or_nil, b.resource_or_nil)
        count += 1
      end
    end

    count
  end

  def self.merge_three(a, b, c)
    if similarity(a, b) >= similarity(b, c)
      merge_two(merge_two(a, b), c)
    else
      merge_two(a, merge_two(b, c))
    end
  end

  def self.merge_two_origins(a, b)
    # a, b are ConfigOrigins
    merge_two(a, b)
  end

  def self.merge_value_origins(stack)
    # stack is an array of AbstractConfigValue
    origins = stack.map { |v| v.origin}
    merge_origins(origins)
  end

  # see also 'merge_two_origins' and 'merge_three_origins'
  def self.merge_origins(stack)
    # stack is an array of ConfigOrigin
    if stack.empty?
      raise Hocon::ConfigError::ConfigBugOrBrokenError, "can't merge empty list of origins"
    elsif stack.length == 1
      stack[0]
    elsif stack.length == 2
      merge_two(stack[0], stack[1])
    else
      remaining = []
      stack.each do |o|
        remaining << o
      end
      while remaining.size > 2
        c = remaining.last
        remaining.delete_at(remaining.size - 1)
        b = remaining.last
        remaining.delete_at(remaining.size - 1)
        a = remaining.last
        remaining.delete_at(remaining.size - 1)

        merged = merge_three(a, b, c)

        remaining << merged
      end

      # should be down to either 1 or 2
      self.merge_origins(remaining)
    end
  end

  # NOTE: skipping 'toFields', 'toFieldsDelta', 'fieldsDelta', 'fromFields',
  # 'applyFieldsDelta', and 'fromBase' from upstream for now, because they appear
  # to be about serialization and we probably won't be supporting that.

end
