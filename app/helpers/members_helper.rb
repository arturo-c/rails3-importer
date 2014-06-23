module MembersHelper
  def export_member_data
    require 'csv'
    CSV.generate do |csv|
      @admin = current_user
      webform_fields = Array.new
      @admin.webform_fields.each do |key, name|
        webform_fields << 'Webform ' + name
      end
      csv << webform_fields.concat(['Member ID', 'First Name', 'Last Name', 'Title', 'Roles', 'Flags', 'Birthday','Parent Email', 'Email', 'Gender', 'UUID', 'Group UUID', 'Submission ID', 'Errors'])
      @members.each do |m|
        roles = Array.new
        flags = Array.new
        m.roles.each do |role, flag|
          roles << role
          flags << flag
        end
        data_fields = Array.new
        data = m.data_fields
        @admin.webform_fields.each do |key, name|
          data_fields << data[key] unless (data.nil? || data[key].nil?)
          data_fields << '' if (data.nil? || data[key].nil?)
        end
        csv << data_fields.concat([m.member_id, m.first_name, m.last_name, m.title, roles.join(', '), flags.join(', '), m.birthday,m.parent_email, m.email, m.gender, m.uuid, m.group_uuid, m.submission_id, m.err])
      end
    end
  end 
end
