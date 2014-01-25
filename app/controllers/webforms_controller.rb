class WebformsController < ApplicationController
  def index
    @webforms = Webform.all.where(:admin_uuid => session[:user_uuid])
  end

  def create
    @webform = Webform.where(:admin_uuid => session[:user_uuid], :uuid => params[:webform][:webform_uuid]).first
    if @webform.nil?
      formatted_data = {}
      data = get_webform_data(params[:webform][:webform_uuid])
      data.each do |cid, values|
        formatted_data.merge!(cid => values['name']) if values['type'] != 'fieldset'
      end
      @webform = Webform.new(:admin_uuid => session[:user_uuid], :uuid => params[:webform][:webform_uuid], :data => formatted_data)
    end

    respond_to do |format|
      if @webform.save
        session[:webform_uuid] = @webform.uuid
        format.html { redirect_to '/members', notice: 'Retrieved webform from allplayers.' }
        format.json { render json: @webform, status: :created, location: @webform }
      else
        format.html { render action: "new" }
        format.json { render json: @webform.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def get_webform_data(uuid)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    webform = client.get_webform(uuid)
    webform['webform']['components']
  end

end
