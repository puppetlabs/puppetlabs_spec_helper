# frozen_string_literal: true

require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/matchers'

RSpec.describe 'have_matching_element matcher' do
  it 'matches when any element matches the pattern' do
    expect(%w[foo bar baz]).to have_matching_element(/bar/)
  end

  it 'does not match when no element matches' do
    expect(%w[foo bar]).not_to have_matching_element(/qux/)
  end
end

RSpec.describe 'exit_with matcher' do
  # exit_with takes a callable (proc) as the actual value, not a block
  it 'matches a proc that exits with the expected code' do
    expect(proc { exit(0) }).to exit_with(0)
  end

  it 'does not match when exit is not called' do
    expect(proc { 1 + 1 }).not_to exit_with(0)
  end

  it 'does not match when a different exit code is used' do
    expect(proc { exit(1) }).not_to exit_with(0)
  end

  it 'includes "exit was not called" in failure message when block does not exit' do
    matcher = exit_with(0)
    matcher.matches?(proc { 1 + 1 })
    expect(matcher.failure_message).to include('exit was not called')
  end

  it 'includes the actual exit code in failure message when wrong code used' do
    matcher = exit_with(0)
    matcher.matches?(proc { exit(1) })
    expect(matcher.failure_message).to include('exited with 1')
  end

  it 'has a failure_message_when_negated' do
    matcher = exit_with(0)
    expect(matcher.failure_message_when_negated).to include('0')
  end

  it 'has a description' do
    expect(exit_with(42).description).to include('42')
  end
end

RSpec.describe 'have_printed matcher' do
  # have_printed takes a callable (proc) as the actual value, not a block
  it 'matches when the proc prints the expected string' do
    expect(proc { print 'hello world' }).to have_printed('hello world')
  end

  it 'matches when the proc prints output matching a regexp' do
    expect(proc { print 'hello world' }).to have_printed(/world/)
  end

  it 'does not match when the proc prints something else' do
    expect(proc { print 'goodbye' }).not_to have_printed('hello')
  end

  it 'raises ArgumentError for unsupported match types' do
    matcher = have_printed(42)
    expect { matcher.matches?(proc { print 'x' }) }.to raise_error(ArgumentError, /No idea how to match/)
  end

  it 'includes the expected string in the failure message when wrong output was printed' do
    matcher = have_printed('expected_string')
    matcher.matches?(proc { print 'something else' })
    expect(matcher.failure_message).to include('expected_string')
  end

  it 'has a description including the expected value' do
    expect(have_printed('hello').description).to include('hello')
  end

  it 'says "nothing was printed" in the failure message when not yet applied' do
    matcher = have_printed('hello')
    expect(matcher.failure_message).to include('nothing was printed')
  end
end
