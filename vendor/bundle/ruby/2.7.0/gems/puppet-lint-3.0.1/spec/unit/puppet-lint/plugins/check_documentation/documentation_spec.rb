require 'spec_helper'

describe 'documentation' do
  let(:class_msg) { 'class not documented' }
  let(:define_msg) { 'defined type not documented' }

  describe 'undocumented class' do
    let(:code) { 'class test {}' }

    it 'only detects a single problem' do
      expect(problems).to have(1).problem
    end

    it 'creates a warning' do
      expect(problems).to contain_warning(class_msg).on_line(1).in_column(1)
    end
  end

  describe 'documented class' do
    let(:code) do
      <<-END
        # foo
        class test {}
      END
    end

    it 'does not detect any problems' do
      expect(problems).to have(0).problems
    end
  end

  describe 'incorrectly documented class' do
    let(:code) do
      <<-END
        # foo

        class test {}
      END
    end

    it 'only detects a single problem' do
      expect(problems).to have(1).problem
    end

    it 'creates a warning' do
      expect(problems).to contain_warning(class_msg).on_line(3).in_column(9)
    end
  end

  describe 'undocumented defined type' do
    let(:code) { 'define test {}' }

    it 'only detects a single problem' do
      expect(problems).to have(1).problem
    end

    it 'creates a warning' do
      expect(problems).to contain_warning(define_msg).on_line(1).in_column(1)
    end
  end

  describe 'documented defined type' do
    let(:code) do
      <<-END
        # foo
        define test {}
      END
    end

    it 'does not detect any problems' do
      expect(problems).to have(0).problems
    end
  end
end
