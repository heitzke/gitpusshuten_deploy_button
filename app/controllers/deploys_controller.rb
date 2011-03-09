class DeploysController < ApplicationController
  respond_to :html

  expose(:project){ Project.find(params[:project_id]) }
  expose(:deploy)

  def create
    deploy.project = project
    deploy.save
    redirect_to project_deploy_path(project, deploy)
  end
end
