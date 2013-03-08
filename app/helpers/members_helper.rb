module MembersHelper
  def export_member_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['email', 'first_name', 'last_name', 'uuid', 'birthday', 'gender', 'group_name', 'errors']
      @members.each do |member|
        csv << [member.email, member.first_name, member.last_name, member.uuid, member.birthday, member.gender, member.group_name, member.err]
      end
    end
  end
end
