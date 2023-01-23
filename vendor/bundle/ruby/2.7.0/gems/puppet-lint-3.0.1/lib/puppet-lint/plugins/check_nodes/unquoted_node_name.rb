# Public: Check the manifest for unquoted node names and record a warning for
# each instance found.
#
# No style guide reference
PuppetLint.new_check(:unquoted_node_name) do
  def check
    node_tokens = tokens.select { |token| token.type == :NODE }
    node_tokens.each do |node|
      node_token_idx = tokens.index(node)
      node_lbrace_tok = tokens[node_token_idx..-1].find { |token| token.type == :LBRACE }
      if node_lbrace_tok.nil?
        notify(
          :error,
          check: :syntax,
          message: 'Syntax error (try running `puppet parser validate <file>`)',
          line: node.line,
          column: node.column,
          description: 'Check for any syntax error and record an error of each instance found.',
          help_uri: nil,
        )
        next
      end

      node_lbrace_idx = tokens.index(node_lbrace_tok)

      invalid_tokens = tokens[node_token_idx..node_lbrace_idx].select { |token| token.type == :NAME && token.value != 'default' }

      invalid_tokens.each do |token|
        notify(
          :warning,
          message: 'unquoted node name found',
          line: token.line,
          column: token.column,
          token: token,
          description: 'Check the manifest for unquoted node names and record a warning for each instance found.',
          help_uri: nil,
        )
      end
    end
  end

  def fix(problem)
    problem[:token].type = :SSTRING
  end
end
