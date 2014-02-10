module MembersHelper
  def export_member_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['_id', 'member_id', 'first_name', 'last_name', 'group_name', 'roles', 'flags', 'join_date', 'birthday',
              'parent_email', 'email', 'address_1', 'address_2', 'city', 'state', 'zip', 'country', 'phone', 'gender',
              'uuid', 'group_uuid', 'submission_id', 'errors']
      @members.each do |m|
        roles = Array.new
        flags = Array.new
        m.roles.each do |role, flag|
          roles << role
          flags << flag
        end
        csv << [m._id, m.member_id, m.first_name, m.last_name, m.group_name, roles.join(', '), flags.join(', '),
                m.join_date, m.birthday, m.parent_email, m.email, m.address_1, m.address_2, m.city, m.state, m.zip,
                m.country, m.phone, m.gender, m.uuid, m.group_uuid, m.submission_id, m.err]
      end
    end
  end 
end
