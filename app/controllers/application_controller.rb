class ApplicationController < ActionController::Base
  protect_from_forgery
end

  def index
    render :layout => 'application'
  end

