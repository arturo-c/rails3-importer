module MembersHelper
  def export_member_data
    require 'csv'
    CSV.generate do |csv|
      csv << Member.column_names
      @members.each do |m|
        group = Group.where(:uuid => m.group_uuid).first if m.group_uuid
        group = Group.where(:name => m.group_name).first unless m.group_uuid
        csv << m
      end
    end
  end 
end
