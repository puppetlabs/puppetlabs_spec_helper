require 'spec_helper'

describe 'inherits_across_namespaces' do
  let(:msg) { 'class inherits across module namespaces' }

  context 'class inheriting from parent in same module namespace' do
    let(:code) { 'class foo::bar inherits foo { }' }

    it 'does not detect any problems' do
      expect(problems).to have(0).problems
    end
  end

  context 'class inheriting from sister in same module namespace' do
    let(:code) { 'class foo::bar inherits foo::baz { }' }

    it 'does not detect any problems' do
      expect(problems).to have(0).problems
    end
  end

  context 'class inheriting from another module namespace' do
    let(:code) { 'class foo::bar inherits baz { }' }

    it 'only detects a single problem' do
      expect(problems).to have(1).problem
    end

    it 'creates a warning' do
      expect(problems).to contain_warning(msg).on_line(1).in_column(25)
    end
  end
end
