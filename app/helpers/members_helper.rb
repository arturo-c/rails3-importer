module MembersHelper
  helper_method :sort_column, :sort_direction
  def export_member_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['_id', 'member_id', 'errors', 'parent_email', 'email', 'first_name',
        'last_name', 'uuid', 'birthday', 'gender', 'group_name', 'roles',
        'address_1', 'address_2', 'city', 'state', 'zip', 'country', 'phone',
        'submission_id', 'group_uuid']
      @members.each do |m|
        group = Group.where(:uuid => m.group_uuid).first if m.group_uuid
        group = Group.where(:name => m.group_name).first unless m.group_uuid
        csv << [m._id, m.member_id ? m.member_id : '', m.err, m.parent_email, m.email,
          m.first_name, m.last_name, m.uuid, m.birthday,
          m.gender, m.group_name, m.roles ? m.roles.join(', ') : '',
          m.address_1, m.address_2, m.city, m.state, m.zip, m.country, m.phone,
          m.submission_id, group ? group.uuid : '']
      end
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class}, :remote => true
  end

  private
  def sort_column
    Member.column_names.include?(params[:sort]) ? params[:sort] : "email"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
  end 
end
