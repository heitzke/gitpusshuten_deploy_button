class ProjectsController < ApplicationController
  respond_to :html

  expose(:projects) { Project.all }
  expose(:project) { Project.find(params[:id])}
end
