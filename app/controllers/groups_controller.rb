class GroupsController < ApplicationController
  # GET /groups
  # GET /groups.json
  def index
    query = Group.all.where(:user_uuid => session[:user_uuid])
    # Introducing class variable for filters so that filters remain consistent
    # throughout ajax calls.
    @@full_groups ||= query

    # Reset filters.
    if params[:commit] == 'Reset Filters'
      params.delete('filter')
      @@full_groups = query
    elsif params.has_key?(:filter)
      query = process_filter(query)
      @@full_groups = query
    end
    @@groups = @groups = query.page(params[:page])

    # Take the pagination out of the csv export.
    @groups = @@full_groups if params[:format] == 'csv'
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @groups }
      format.js { @groups }
      format.csv # index.csv.erb
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])
    @group[:local] = true
    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'New group was successfully created.' }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:new_group])
        format.html { redirect_to @group, notice: 'New group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find(params[:id])
    @group.update_attributes(:deleted => true)
    client = AllPlayers.client
    client.group_delete(@group[:uuid])

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :no_content }
    end
  end

  def destroy_all
    @groups = @@full_groups
    @groups.each do |group|
      group.destroy
    end
  end    

  def export
    @group = Group.find(params[:id])
    @group.create_group
    @group
  end

  def export_all
    @groups = @@groups
    @groups.each do |group|
      group.create_group
    end
    @groups
  end

  def import_csv
    require 'csv'
    parsed_file = CSV.foreach(params[:csv].tempfile,:headers => true) do |row|
      row = row.to_hash.with_indifferent_access
      formatted_row = row.to_hash.symbolize_keys
      formatted_row[:user_uuid] = session[:user_uid]
      formatted_row[:org_webform_uuid] = ENV["WEBFORM_UUID"]
      Group.create!(formatted_row)
    end
    redirect_to groups_url
  end

  def clear_errors
    @groups = @@groups
    @groups.update_all(:err => nil)
    @groups
  end

  def get_members
    @group = Group.find(params[:id])
    @group.get_subgroups_members
    @group
  end

  def get_all_members
    groups = @@full_groups
    groups.each do |group|
      group.get_group_members
    end
    groups
  end

  def get_roles
    @group = Group.find(params[:id])
    @group.get_subgroups_members_roles
    @group
  end

  def get_groups
    @admin = Admin.find(session[:user_id])
    @admin.get_admin_groups
  end

  private
  def process_filter(query)
    filter = params[:filter]
    query = query.where(:user_uuid => session[:user_uuid])
    query = query.where(:status => filter[:status]) if filter[:status].present?
    # Filter by the group selected and all subgroups if checkbox enabled.
    if (filter[:subgroups].present? && filter[:subgroups] == "1" && filter[:name].present?)
      group = Group.where(:name => params[:filter][:name]).first
      # Reset the subgroups variable.
      @subgroups = []
      # Recursive function to get all subgroups.
      get_subgroups(group.uuid)
      # Include the top level group.
      @subgroups << group.name
      query = query.in(name: @subgroups)
    elsif filter[:name].present?
      group = filter[:name]
      query = query.where(:name => /.*#{group}.*/)
    end
    return query
  end

  # Recursive function to get all the groups subgroups.
  def get_subgroups(group_uuid)
    @subgroups ||= []

    subgroups = Group.any_of(:groups_above => group_uuid).entries
    return if subgroups.first.nil?
    subgroups.each do |subgroup|
      @subgroups << subgroup.name
      get_subgroups(subgroup.uuid)
    end
  end
end
