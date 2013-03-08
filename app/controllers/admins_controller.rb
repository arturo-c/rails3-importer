class AdminsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :correct_user?, :except => [:index]

  def index
    @admins = Admin.all
  end

  def edit
    @admin = Admin.find(params[:id])
  end
  
  def update
    @admin = Admin.find(params[:id])
    if @admin.update_attributes(params[:user])
      redirect_to @admin
    else
      render :edit
    end
  end


  def show
    @admin = Admin.find(params[:id])
  end

end
