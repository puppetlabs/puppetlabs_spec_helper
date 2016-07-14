
desc "Run beaker acceptance tests"
RSpec::Core::RakeTask.new(:beaker) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec/acceptance'
end

desc "List available beaker nodesets"
task 'beaker:sets' do
  beaker_node_sets.each do |set|
    puts set
  end
end

# alias for compatibility
task 'beaker_nodes' => 'beaker:sets'

desc 'Try to use vagrant to login to the Beaker node'
task 'beaker:ssh', [:set, :node] do |_task, args|
  set = args[:set] || ENV['BEAKER_set'] || ENV['RS_SET'] || 'default'
  node = args[:node]
  vagrant_ssh set, node
end

beaker_node_sets.each do |set|
  desc "Run the Beaker acceptance tests for the node set '#{set}'"
  task "beaker:#{set}" do
    ENV['BEAKER_set'] = set
    Rake::Task['beaker'].reenable
    Rake::Task['beaker'].invoke
  end

  desc "Use vagrant to login to a node from the set '#{set}'"
  task "beaker:ssh:#{set}", [:node] do |_task, args|
    node = args[:node]
    vagrant_ssh set, node
  end
end

# get the array of Beaker set names
# @return [Array<String>]
def beaker_node_sets
  return @beaker_nodes if @beaker_nodes
  @beaker_nodes = Dir['spec/acceptance/nodesets/*.yml'].sort.map do |node_set|
    node_set.slice!('.yml')
    File.basename(node_set)
  end
end

# Use "vagrant ssh" to login to the given node in the node set
# @param set [String] The name of the node set (yml file)
# @param node [String] The name of the node in the set. For multi-node sets.
def vagrant_ssh(set, node = nil)
  vagrant_yml_dir = File.join '.vagrant', 'beaker_vagrant_files', "#{set}.yml"
  vagrant_file = File.join vagrant_yml_dir, 'Vagrantfile'
  unless File.file? vagrant_file
    puts "There is no Vagrantfile at: '#{vagrant_file}'. Perhaps, the node is not created or is destroyed."
    exit 1
  end
  Dir.chdir(vagrant_yml_dir) do
    command = 'vagrant ssh'
    command += " #{node}" if node
    # Vagrant is not distributed as a normal gem
    # and we should protect it from the current Ruby environment
    env = {
        'RUBYLIB' => nil,
        'GEM_PATH' => nil,
        'BUNDLE_BIN_PATH' => nil,
    }
    system env, command
  end
end
