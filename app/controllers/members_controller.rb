class MembersController < ApplicationController
  helper_method :sort_column, :sort_direction, :sortable

  # GET /members
  # GET /members.json
  def index
    query = Member.all.where(:admin_uuid => session[:user_uuid]).order_by(sort_column + ' ' + sort_direction)

    # Reset filters.
    if params[:commit] == 'Reset Filters'
      params.delete('filter')
    elsif params.has_key?(:filter)
      query = process_filter(query, params)
      @@csv_members = query
    end

    # Introducing class variable for filters so that filters remain consistent
    # throughout ajax calls.
    @@full_members = query
    @@csv_members ||= @@full_members

    @@members = @members = query.page(params[:page]).per(params[:per_page])

    # Take the pagination out of the csv export.
    @members = @@csv_members if params[:format] == 'csv'

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @members }
      format.js { @members }
      format.csv # index.csv.erb
    end
  end

  # GET /members/1
  # GET /members/1.json
  def show
    @member = Member.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @member }
    end
  end

  # GET /members/new
  # GET /members/new.json
  def new
    @member = Member.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @member }
    end
  end

  # GET /members/1/edit
  def edit
    @member = Member.find(params[:id])
  end

  # POST /members
  # POST /members.json
  def create
    r = params[:member]
    @member = Member.where(:email => r[:email], :group_name => r[:group_name], :admin_uuid => session[:user_uuid]).first
    r = @member.attributes.merge(r) unless @member.nil?
    @member = Member.new(r) if @member.nil?
    @member.update_attributes(r) unless @member.nil?
    unless @member.err
      @member.get_member_uuid
    end
    respond_to do |format|
      unless @member.nil?
        format.html { redirect_to @member, notice: 'Member was successfully created.' }
        format.json { render json: @member, status: :created, location: @member }
      else
        format.html { render action: "new" }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /members/1
  # PUT /members/1.json
  def update
    @member = Member.find(params[:id])

    respond_to do |format|
      if @member.update_attributes(params[:member])
        unless @member.err
          @member.get_member_uuid
        end
        format.html { redirect_to @member, notice: 'Member was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /members/1
  # DELETE /members/1.json
  def destroy
    @member = Member.find(params[:id])
    @member.destroy

    respond_to do |format|
      format.html { redirect_to members_url }
      format.json { head :no_content }
    end
  end
 
  def destroy_all
    @members = @@full_members
    @members.each do |member|
      member.destroy
    end
    render :live
  end

  def get_duplicates
    @@full_members = @members = Member.find(:all, :group => [:first_name, :last_name, :birthday, :group_uuid], :having => "count(*) > 1" )
    render :live
  end

  def export
    @member = Member.find(params[:id])
    @member.get_member_uuid
    render :live
  end

  def export_all
    @members = @@full_members
    @members.each do |member|
      member.get_member_uuid
    end
    render :live
  end

  def import_csv
    admin = Admin.where('uuid' => session[:user_uuid]).first
    SmarterCSV.process(params[:csv].tempfile, {:chunk_size => 100, :strip_chars_from_headers => '"', :col_sep => ','}) do |chunk|
      admin.process_import(chunk)
    end
    redirect_to members_url
  end

  def clear_errors
    @members = @@members
    @members.update_all(:err => nil)
    render :live
  end

  def live
    @@members ||= @members
    @members = @@members
  end

  def add_members_job
    @@full_members.each do |member|
      member.add_to_group
    end
    @members = @@full_members
    render :live
  end

  def add_to_group_and_subgroups
    @@full_members.each do |member|
      member.add_to_group_and_subgroups
    end
    @members = @@full_members
    render :live
  end

  def remove_from_group
    @@full_members.each do |member|
      member.remove_from_group
    end
    @members = @@full_members
    render :live
  end

  def remove_from_group_and_subgroups
    @@full_members.each do |member|
      member.remove_from_group_and_subgroups
    end
    @members = @@full_members
    render :live
  end


  def get_roles
    @@full_members.each do |member|
      member.get_group_member_roles
    end
    @members = @@full_members
    render :live
  end

  def get_submissions
    @@full_members.each do |member|
      member.get_submission
    end
    @members = @@full_members
    render :live
  end

  def get_unique_submissions
    @@full_members.each do |member|
      member.get_unique_submission
    end
    @members = @@full_members
    render :live
  end

  def get_webform_data
    @@full_members.each do |member|
      member.get_webform_data
    end
    @members = @@full_members
    render :live
  end

  def assign_all
    @@full_members.each do |member|
      member.assign_submission
    end
    @members = @@full_members
    render :live
  end

  def assign
    @member = Member.find(params[:id])
    @member.assign_submission
    render :live
  end

  def set_completed
    @@full_members.each do |member|
      member.status = params[:set_status][:status]
      member.save
    end
    @members = @@full_members
    render :live
  end

  private
  def process_filter(query, params)
    query = query.where(:admin_uuid => session[:user_uuid])
    if params[:filter][:email].present?
      email = params[:filter][:email]
      query = query.where(:email => /.*#{email}.*/)
    end
    if params[:filter][:errors].present?
      errors = params[:filter][:errors]
      query = query.where(:err => /.*#{errors}.*/)
    end
    query = query.where(:status => params[:filter][:status]) if params[:filter][:status].present?
    query = query.where(:first_name => params[:filter][:first_name]) if params[:filter][:first_name].present?
    query = query.where(:member_id => params[:filter][:member_id]) if params[:filter][:member_id].present?
    query = query.where(:last_name => params[:filter][:last_name]) if params[:filter][:last_name].present?
    if params[:filter][:roles].present?
      roles = params[:filter][:roles]
      query = query.where(:roles => /.*#{roles}.*/)
    end

    # Filter by the group selected and all subgroups if checkbox enabled.
    if (params[:filter][:subgroups].present? && params[:filter][:subgroups] == "1" && params[:filter][:group_name].present?)
      group = Group.where(:name => params[:filter][:group_name]).first
      # Reset the subgroups variable.
      @subgroups = []
      # Recursive function to get all subgroups.
      get_subgroups(group.uuid)
      # Include the top level group.
      @subgroups << group.name
      query = query.in(group_name: @subgroups)
    elsif params[:filter][:group_name].present?
      group = params[:filter][:group_name]
      query = query.where(:group_name => /.*#{group}.*/)
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

  private
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    view_context.link_to(title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class})
  end

  def sort_column
    Member.fields.keys.include?(params[:sort]) ? params[:sort] : "email"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
  end

end
