class Deploy < ActiveRecord::Base
  belongs_to :project

  def to_s
    [guid, domain_name].join(' - ')
  end

  def handle_deploy!
    deployment_handler.handle_deployment
  end

  def deployment_handler
    ProjectDeploymentHandler.new(guid, project.git_repo, server_ip, root_password, domain_name, self)
  end

  def log(message)
    self.log_output ||= ''
    self.log_output += message
    self.save
  end
end
