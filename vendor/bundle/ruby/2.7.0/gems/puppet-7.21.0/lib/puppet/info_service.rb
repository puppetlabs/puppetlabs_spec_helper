
module Puppet::InfoService
  require_relative 'info_service/class_information_service'
  require_relative 'info_service/task_information_service'
  require_relative 'info_service/plan_information_service'

  def self.classes_per_environment(env_file_hash)
    Puppet::InfoService::ClassInformationService.new.classes_per_environment(env_file_hash)
  end

  def self.tasks_per_environment(environment_name)
    Puppet::InfoService::TaskInformationService.tasks_per_environment(environment_name)
  end

  def self.task_data(environment_name, module_name, task_name)
    Puppet::InfoService::TaskInformationService.task_data(environment_name, module_name, task_name)
  end

  def self.plans_per_environment(environment_name)
    Puppet::InfoService::PlanInformationService.plans_per_environment(environment_name)
  end

  def self.plan_data(environment_name, module_name, plan_name)
    Puppet::InfoService::PlanInformationService.plan_data(environment_name, module_name, plan_name)
  end
end
