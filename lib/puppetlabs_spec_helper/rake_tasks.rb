require 'rake'
require 'rspec/core/rake_task'
require 'yaml'

task :default => [:help]

desc "Run spec tests on an existing fixtures directory"
RSpec::Core::RakeTask.new(:spec_standalone) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec/{classes,defines,unit,functions,hosts}/**/*_spec.rb'
end

desc "Generate code coverage information"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

# This is a helper for the self-symlink entry of fixtures.yml
def source_dir
  Dir.pwd
end

def fixtures(category)
  begin
    fixtures = YAML.load_file(".fixtures.yml")["fixtures"]
  rescue Errno::ENOENT
    return {}
  end

  if not fixtures
    abort("malformed fixtures.yml")
  end

  result = {}
  if fixtures.include? category
    fixtures[category].each do |fixture, source|
      target = "spec/fixtures/modules/#{fixture}"
      real_source = eval('"'+source+'"')
      result[real_source] = target
    end
  end
  return result
end

desc "Create the fixtures directory"
task :spec_prep do
  fixtures("repositories").each do |repo, target|
    File::exists?(target) || system("git clone #{repo} #{target}")
  end

  FileUtils::mkdir_p("spec/fixtures/modules")
  fixtures("symlinks").each do |source, target|
    File::exists?(target) || FileUtils::ln_s(source, target)
  end

  FileUtils::mkdir_p("spec/fixtures/manifests")
  FileUtils::touch("spec/fixtures/manifests/site.pp")
end

desc "Clean up the fixtures directory"
task :spec_clean do
  fixtures("repositories").each do |repo, target|
    FileUtils::rm_rf(target)
  end

  fixtures("symlinks").each do |source, target|
    FileUtils::rm(target)
  end

  FileUtils::rm("spec/fixtures/manifests/site.pp")
end

desc "Run spec tests in a clean fixtures directory"
task :spec do
  Rake::Task[:spec_prep].invoke
  Rake::Task[:spec_standalone].invoke
  Rake::Task[:spec_clean].invoke
end

desc "Build puppet module package"
task :build do
  # This will be deprecated once puppet-module is a face.
  begin
    Gem::Specification.find_by_name('puppet-module')
  rescue Gem::LoadError, NoMethodError
    require 'puppet/face'
    pmod = Puppet::Face['module', :current]
    pmod.build('./')
  end
end

desc "Clean a built module package"
task :clean do
  FileUtils.rm_rf("pkg/")
end

desc "Check puppet manifests with puppet-lint"
task :lint do
  require 'puppet-lint/tasks/puppet-lint'
end

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end
