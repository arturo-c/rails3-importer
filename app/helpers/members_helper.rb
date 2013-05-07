module MembersHelper
  def export_member_data
    require 'csv'
    CSV.generate do |csv|
      csv << Member.column_names.merge(['group_uuid'])
      @members.each do |m|
        group = Group.where(:uuid => m.group_uuid).first if m.group_uuid
        group = Group.where(:name => m.group_name).first unless m.group_uuid
        csv << m.columns.merge([group.uuid])
      end
    end
  end 
end
