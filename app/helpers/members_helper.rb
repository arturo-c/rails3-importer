module MembersHelper
  def export_member_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['_id', 'member_id', 'errors', 'parent_email', 'email', 'first_name',
        'last_name', 'uuid', 'birthday', 'gender', 'group_name', 'roles',
        'address_1', 'address_2', 'city', 'state', 'zip', 'country', 'phone',
        'submission_id', 'group_uuid', 'join_date']
      @members.each do |m|
        group = Group.where(:uuid => m.group_uuid).first if m.group_uuid
        group = Group.where(:name => m.group_name).first unless m.group_uuid
        csv << [m._id, m.member_id ? m.member_id : '', m.err, m.parent_email, m.email,
          m.first_name, m.last_name, m.uuid, m.birthday,
          m.gender, m.group_name, m.roles ? m.roles.join(', ') : '',
          m.address_1, m.address_2, m.city, m.state, m.zip, m.country, m.phone,
          m.submission_id, group ? group.uuid : '', m.join_date ? m.join_date : '']
      end
    end
  end 
end
