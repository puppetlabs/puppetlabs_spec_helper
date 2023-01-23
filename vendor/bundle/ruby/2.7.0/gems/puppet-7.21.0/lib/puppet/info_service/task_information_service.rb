class Puppet::InfoService::TaskInformationService
  require_relative '../../puppet/module'

  def self.tasks_per_environment(environment_name)
    # get the actual environment object, raise error if the named env doesn't exist
    env = Puppet.lookup(:environments).get!(environment_name)

    env.modules.map do |mod|
      mod.tasks.map do |task|
        # If any task is malformed continue to list other tasks in module
        begin
          task.validate
          {:module => {:name => task.module.name}, :name => task.name, :metadata => task.metadata}
        rescue Puppet::Module::Task::Error => err
          Puppet.log_exception(err, 'Failed to validate task')
          nil
        end
      end
    end.flatten.compact
  end

  def self.task_data(environment_name, module_name, task_name)
    # raise EnvironmentNotFound if applicable
    Puppet.lookup(:environments).get!(environment_name)

    pup_module = Puppet::Module.find(module_name, environment_name)
    if pup_module.nil?
      raise Puppet::Module::MissingModule, _("Module %{module_name} not found in environment %{environment_name}.") %
                                            {module_name: module_name, environment_name: environment_name}
    end

    task = pup_module.tasks.find { |t| t.name == task_name }
    if task.nil?
      raise Puppet::Module::Task::TaskNotFound.new(task_name, module_name)
    end

    begin
      task.validate
      {:metadata => task.metadata, :files => task.files}
    rescue Puppet::Module::Task::Error => err
      { :metadata => nil, :files => [], :error => err.to_h }
    end
  end
end
