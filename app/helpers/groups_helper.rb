module GroupsHelper
  def export_group_data
    require 'csv'
    CSV.generate do |csv|
      csv << ['uuid', 'title', 'description', 'zip', 'category', 'groups_above']
      @groups.each do |group|
        csv << [group.uuid, group.title, group.description, group.zip, group.category, group.groups_above]
      end
    end
  end
end
