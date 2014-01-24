class HomeController < ApplicationController
  def index
    admin = Admin.where(:name => 'USA Rugby Admin').first
    session[:user_id] = admin.id
    session[:user_uuid] = admin.uuid
    @admin_info = {:name => admin.name, :picture => 'http://files.allplayers.com/sites/default/files/pictures/picture-53118-2011-11-22-00-02.png'}
    #if session[:user_info]
      #@admin_info = session[:user_info]
    #end
  end
end
