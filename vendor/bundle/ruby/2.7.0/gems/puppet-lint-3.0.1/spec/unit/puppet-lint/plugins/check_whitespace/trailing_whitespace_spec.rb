require 'spec_helper'

describe 'trailing_whitespace' do
  let(:msg) { 'trailing whitespace found' }

  context 'with fix disabled' do
    context 'line with trailing whitespace' do
      let(:code) { 'foo ' }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates an error' do
        expect(problems).to contain_error(msg).on_line(1).in_column(4)
      end
    end

    context 'line without code and trailing whitespace' do
      let(:code) do
        [
          'class {',
          '  ',
          '}',
        ].join("\n")
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates an error' do
        expect(problems).to contain_error(msg).on_line(2).in_column(1)
      end
    end
  end

  context 'with fix enabled' do
    before(:each) do
      PuppetLint.configuration.fix = true
    end

    after(:each) do
      PuppetLint.configuration.fix = false
    end

    context 'single line with trailing whitespace' do
      let(:code) { 'foo ' }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(4)
      end

      it 'removes the trailing whitespace' do
        expect(manifest).to eq('foo')
      end
    end

    context 'multiple lines with trailing whitespace' do
      let(:code) { "foo    \nbar" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(4)
      end

      it 'removes the trailing whitespace' do
        expect(manifest).to eq("foo\nbar")
      end
    end

    context 'line without code and trailing whitespace' do
      let(:code) do
        [
          'class foo {',
          '  ',
          '}',
        ].join("\n")
      end

      let(:fixed) do
        [
          'class foo {',
          '',
          '}',
        ].join("\n")
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates an error' do
        expect(problems).to contain_fixed(msg).on_line(2).in_column(1)
      end

      it 'removes the trailing whitespace' do
        expect(manifest).to eq(fixed)
      end
    end
  end
end
