require 'spec_helper'

describe 'star_comments' do
  let(:msg) { '/* */ comment found' }

  context 'with fix disabled' do
    context 'multiline comment w/ one line of content' do
      let(:code) do
        <<-END
          /* foo
          */
        END
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(11)
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

    context 'multiline comment w/ no indents' do
      let(:code) do
        <<-END.gsub(%r{^ {10}}, '')
          /* foo *
           *     *
           * bar */
        END
      end

      let(:fixed) do
        <<-END.gsub(%r{^ {10}}, '')
          # foo *
          # *
          # bar
        END
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(1)
      end

      it 'converts the multiline comment' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multiline comment w/ one line of content' do
      let(:code) do
        <<-END
          /* foo
          */
        END
      end

      let(:fixed) do
        <<-END
          # foo
        END
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(11)
      end

      it 'converts the multiline comment' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multiline comment w/ multiple line of content' do
      let(:code) do
        <<-END
          /* foo
           * bar
           * baz
           */
          notify { 'foo': }
        END
      end

      let(:fixed) do
        <<-END
          # foo
          # bar
          # baz
          notify { 'foo': }
        END
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(11)
      end

      it 'converts the multiline comment' do
        expect(manifest).to eq(fixed)
      end
    end
  end
end
