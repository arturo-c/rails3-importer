class HomeController < ApplicationController
  def index
    #client = AllPlayers::Client.new(ENV["HOST"])
    #client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    #user = client.user_get(ENV["GROUP_ADMIN_UUID"])
    #admin = Admin.where(:uuid => user['uuid']).first
    #admin = Admin.create({:uuid => user['uuid'], :name => user['username']}) unless admin
    #session[:user_id] = admin.id
   # session[:user_uuid] = admin.uuid
    #@admin_info = {:name => admin.name, :picture => 'http://files.allplayers.com/sites/default/files/pictures/picture-53118-2011-11-22-00-02.png'}
    if session[:user_info]
      @admin_info = session[:user_info]
    end
  end
end
