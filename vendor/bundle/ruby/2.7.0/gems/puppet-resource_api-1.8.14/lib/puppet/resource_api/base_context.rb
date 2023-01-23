# frozen_string_literal: true

require 'puppet/resource_api/type_definition'

# rubocop:disable Style/Documentation
module Puppet; end
module Puppet::ResourceApi; end
# rubocop:enable Style/Documentation

# This class provides access to all common external dependencies of providers and transports.
# The runtime environment will inject an appropriate implementation.
class Puppet::ResourceApi::BaseContext
  attr_reader :type

  def initialize(definition)
    if definition.is_a?(Hash)
      # this is only for backwards compatibility
      @type = Puppet::ResourceApi::TypeDefinition.new(definition)
    elsif definition.is_a? Puppet::ResourceApi::BaseTypeDefinition
      @type = definition
    else
      raise ArgumentError, 'BaseContext requires definition to be a child of Puppet::ResourceApi::BaseTypeDefinition, not <%{actual_type}>' % { actual_type: definition.class }
    end
  end

  def device
    raise 'Received device() on an unprepared BaseContext. Use a PuppetContext instead.'
  end

  def transport
    raise 'No transport available.'
  end

  def failed?
    @failed
  end

  def reset_failed
    @failed = false
  end

  def feature_support?(feature)
    Puppet.deprecation_warning('context.feature_support? is deprecated. Please use context.type.feature? instead.')
    type.feature?(feature)
  end

  [:debug, :info, :notice, :warning, :err].each do |level|
    define_method(level) do |*args|
      if args.length == 1
        message = "#{@context || @type.name}: #{args.last}"
      elsif args.length == 2
        resources = format_titles(args.first)
        message = "#{resources}: #{args.last}"
      else
        message = args.map(&:to_s).join(', ')
      end
      send_log(level, message)
    end
  end

  [:creating, :updating, :deleting].each do |method|
    define_method(method) do |titles, message: method.to_s.capitalize, &block|
      start_time = Time.now
      setup_context(titles, message)
      begin
        debug('Start')
        block.call
        notice("Finished in #{format_seconds(Time.now - start_time)} seconds")
      rescue StandardError => e
        log_exception(e, message: "Failed after #{format_seconds(Time.now - start_time)} seconds")
        @failed = true
      ensure
        @context = nil
      end
    end
  end

  def failing(titles, message: 'Failing')
    start_time = Time.now
    setup_context(titles, message)
    begin
      debug('Start')
      yield
      warning("Finished failing in #{format_seconds(Time.now - start_time)} seconds")
    rescue StandardError => e
      log_exception(e, message: "Failed after #{format_seconds(Time.now - start_time)} seconds")
      @failed = true
    ensure
      @context = nil
    end
  end

  def processing(title, is, should, message: 'Processing')
    raise "#{__method__} only accepts a single resource title" if title.respond_to?(:each)
    start_time = Time.now
    setup_context(title, message)
    begin
      debug("Starting processing of #{title} from #{is} to #{should}")
      yield
      notice("Finished processing #{title} in #{format_seconds(Time.now - start_time)} seconds: #{should}")
    rescue StandardError => e
      log_exception(e, message: "Failed processing #{title} after #{format_seconds(Time.now - start_time)} seconds")
      @failed = true
    ensure
      @context = nil
    end
  end

  [:created, :updated, :deleted].each do |method|
    define_method(method) do |titles, message: method.to_s.capitalize|
      notice("#{message}: #{titles}")
    end
  end

  def processed(title, is, should)
    raise "#{__method__} only accepts a single resource title" if title.respond_to?(:each)
    notice("Processed #{title} from #{is} to #{should}")
  end

  def attribute_changed(title, attribute, is, should, message: nil)
    raise "#{__method__} only accepts a single resource title" if title.respond_to?(:each)
    printable_is = 'nil'
    printable_should = 'nil'
    if is
      printable_is = is.is_a?(Numeric) ? is : "'#{is}'"
    end
    if should
      printable_should = should.is_a?(Numeric) ? should : "'#{should}'"
    end
    notice("#{title}: attribute '#{attribute}' changed from #{printable_is} to #{printable_should}#{message ? ": #{message}" : ''}")
  end

  def failed(titles, message: 'Updating has failed')
    setup_context(titles)
    begin
      err(message)
      # raise message
    ensure
      @context = nil
    end
  end

  def log_exception(exception, message: 'Error encountered', trace: false)
    message = "#{message}: #{exception}"
    if trace
      message += "\n"
      message += exception.backtrace.join("\n")
    end
    err(message)
  end

  def send_log(_level, _message)
    raise 'Received send_log() on an unprepared BaseContext. Use IOContext, or PuppetContext instead.'
  end

  private

  def format_titles(titles)
    if titles.length.zero? && !titles.is_a?(String)
      @type.name
    else
      "#{@type.name}[#{[titles].flatten.compact.join(', ')}]"
    end
  end

  def setup_context(titles, message = nil)
    @context = format_titles(titles)
    @context += ": #{message}" if message
  end

  def format_seconds(seconds)
    return '%.6f' % seconds if seconds < 1
    '%.2f' % seconds
  end
end
