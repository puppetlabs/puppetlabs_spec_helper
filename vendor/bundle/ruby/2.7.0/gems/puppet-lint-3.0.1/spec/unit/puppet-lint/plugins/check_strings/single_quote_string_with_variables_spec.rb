require 'spec_helper'

describe 'single_quote_string_with_variables' do
  let(:msg) { 'single quoted string containing a variable found' }

  context 'multiple strings in a line' do
    let(:code) { "\"aoeu\" '${foo}'" }

    it 'only detects a single problem' do
      expect(problems).to have(1).problem
    end

    it 'creates an error' do
      expect(problems).to contain_error(msg).on_line(1).in_column(8)
    end
  end

  context 'single quoted inline template with dollar signs has no problems' do
    let(:code) do
      <<-END
        $list = ['one', 'two', 'three']
        file { '/tmp/text.txt':
          ensure  => file,
          content => inline_template('<% $list.each |$item| { %><%= "${item}\n" %><% } %>'),
        }
      END
    end

    it { expect(problems).to have(0).problem }
  end

  context 'single quoted inline epp with dollar signs has no problems' do
    let(:code) do
      <<-END
        $list = ['one', 'two', 'three']
        file { '/tmp/text.txt':
          ensure  => file,
          content => inline_template('<% @list.each do |item| %><%= @item %>\n<% end %>'),
        }
      END
    end

    it { expect(problems).to have(0).problem }
  end
end
